package Dist::Zilla::Plugin::Author::SKIRMESS::ProjectSkeleton;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.000';

use Moose;

with qw(
  Dist::Zilla::Role::BeforeBuild
  Dist::Zilla::Role::TextTemplate
);

use Config::Std { def_sep => q{=} };
use CPAN::Meta::YAML ();
use CPAN::Perl::Releases qw(perl_versions);
use HTTP::Tiny ();
use JSON::MaybeXS qw(decode_json);
use List::Util qw(any uniq);
use MetaCPAN::Client;
use MetaCPAN::Helper;
use Path::Tiny qw(path);
use version 0.77;

use constant DZIL_6_NEEDS_PERL      => 'v5.14';
use constant WITH_USE_64_BIT_INT    => 1;
use constant WITHOUT_USE_64_BIT_INT => 2;

use namespace::autoclean;

sub mvp_multivalue_args {
    return (
        qw(
          appveyor_author_testing_perl
          kwalitee_disable_test
          skip
          stopwords
          travis_ci_author_testing_perl
          travis_ci_osx_perl
          )
    );
}

has appveyor_author_testing_perl => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [qw(5.24)] },
);

has appveyor_earliest_perl => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    default => sub { $_[0]->ci_earliest_perl },
);

has appveyor_test_on_cygwin => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has appveyor_test_on_cygwin64 => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has appveyor_test_on_strawberry => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has ci_dist_zilla => (
    is      => 'ro',
    isa     => 'Bool',
    default => undef,
);

has ci_earliest_perl => (
    is      => 'ro',
    isa     => 'Str',
    default => '5.8',
);

has kwalitee_disable_test => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

has makefile_pl_exists => (
    is      => 'ro',
    isa     => 'Bool',
    default => 1,
);

has skip => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

has stopwords => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [] },
);

has travis_ci_author_testing_perl => (
    is      => 'ro',
    isa     => 'Maybe[ArrayRef]',
    default => sub { [qw(5.24)] },
);

has travis_ci_osx_perl => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [qw(5.18)] },
);

has ua => (
    is      => 'rw',
    lazy    => 1,
    default => sub { HTTP::Tiny->new() },
);

has _generated_string => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Automatically generated file; DO NOT EDIT.',
);

has _strawberry_releases => (
    is      => 'ro',
    isa     => 'ArrayRef',
    lazy    => 1,
    builder => '_build_strawberry_releases',
);

sub before_build {
    my ($self) = @_;

    my %file_to_skip = map { $_ => 1 } grep { defined && !m{ ^ \s* $ }xsm } @{ $self->skip };

  FILE:
    for my $file ( sort $self->files() ) {
        next FILE if exists $file_to_skip{$file};

        $self->_write_file($file);
    }

    return;
}

sub _write_file {
    my ( $self, $file ) = @_;

    $file = path($file);

    if ( -e $file ) {
        $file->remove();
    }
    else {
        # If the file does not yet exist, the basedir might also not
        # exist. Create it if required.
        my $parent = $file->parent();
        if ( !-e $parent ) {
            $self->log_debug("Creating directory $parent");
            $parent->mkpath();
        }
    }

    $self->log_debug("Generate file $file");

    # write the file to disk
    $file->spew( $self->file($file) );

    return;
}

## no critic (Documentation::RequirePodAtEnd)

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::SKIRMESS::ProjectSkeleton - maintain a base set of files in the project

=head1 VERSION

Version 1.000

=head1 SYNOPSIS

This plugin is part of the
L<Dist::Zilla::PluginBundle::Author::SKIRMESS|Dist::Zilla::PluginBundle::Author::SKIRMESS>
bundle and should not be used outside of that.

=head1 DESCRIPTION

This plugin creates a collection of files that are shared between all my
CPAN distributions which makes it easy to keep them all up to date.

The following files are created in the repository and in the distribution:

=cut

# Returns the latest releases of Dist::Zilla for major release 5 and 6
sub _latest_dist_zilla_releases {
    my ($self) = @_;

    state $result_ref;
    return $result_ref if defined $result_ref;

    my $t_start = time;
    $self->log('Finding latest Dist::Zilla release');

    my $helper = MetaCPAN::Helper->new(
        client => MetaCPAN::Client->new( ua => $self->ua ),
    );

    my $dist       = $helper->module2dist('Dist::Zilla');
    my $result_set = $helper->dist2releases($dist);

    my @latest = (
        [ version->parse('v7'), version->parse('v7') ],
        [ version->parse('v6'), version->parse('v6') ],
        [ version->parse('v5'), version->parse('v5') ],
    );

  RELEASE:
    while ( defined( my $release = $result_set->next ) ) {
        my $version = version->parse( $release->version );

        for my $latest_ref (@latest) {
            if ( $version >= $latest_ref->[0] ) {
                if ( $version > $latest_ref->[1] ) {
                    $latest_ref->[1] = $version;
                }

                next RELEASE;
            }
        }

        # skip all releases < 5
    }

    if ( $latest[0]->[0] != $latest[0]->[1] ) {
        $self->log("New Dist::Zilla version found: $latest[0]->[1]\n");
    }

    my $duration = time - $t_start;
    $self->log( "Found Dist::Zilla $latest[-1]->[1] and $latest[-2]->[1] after $duration second" . ( $duration == 1 ? q{} : 's' ) );

    $result_ref = {
        '5' => $latest[-1]->[1]->numify,
        '6' => $latest[-2]->[1]->numify,
    };

    return $result_ref;
}

# Returns an iterator that can be used to iterate over all the perlcritic
# policies in a policy distribution.
sub _perl_critic_policy_from_distribution {
    my ( $self, $distribution ) = @_;

    my $url = "http://cpanmetadb.plackperl.org/v1.0/package/$distribution";
    $self->log_debug("Downloading '$url'...");
    my $res = $self->ua->get($url);

    $self->log_fatal("Cannot download '$url': $res->{reason}") if !$res->{success};

    my $yaml = CPAN::Meta::YAML->read_string( $res->{content} ) or $self->log_fatal( CPAN::Meta::YAML->errstr );
    my $meta = $yaml->[0];

    $self->log_fatal('Unable to parse returned data') if !exists $meta->{provides};

    my @policies;
  MODULE:
    for my $module ( keys %{ $meta->{provides} } ) {
        if ( $module =~ m{ ^ Perl::Critic::Policy:: ( .+ ) }xsm ) {
            push @policies, $1;
        }
    }

    my @stack = sort { lc $a cmp lc $b } @policies;

    return sub {
        return if !@stack;
        return shift @stack;
    };
}

# Returns an iterator that iterates over the perlcritic policy distributions
# we use.
sub _perl_critic_policy_distributions {
    my ($self) = @_;

    my @stack = (
        'Perl::Critic',
        'Perl::Critic::Bangs',
        'Perl::Critic::Moose',
        'Perl::Critic::Freenode',
        'Perl::Critic::Policy::HTTPCookies',
        'Perl::Critic::Itch',
        'Perl::Critic::Lax',
        'Perl::Critic::More',
        'Perl::Critic::PetPeeves::JTRAMMELL',
        'Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays',
        'Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr',
        'Perl::Critic::Policy::Moo::ProhibitMakeImmutable',
        'Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice',
        'Perl::Critic::Policy::Perlsecret',
        'Perl::Critic::Policy::TryTiny::RequireBlockTermination',
        'Perl::Critic::Policy::TryTiny::RequireUse',
        'Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection',
        'Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter',
        'Perl::Critic::Pulp',
        'Perl::Critic::StricterSubs',
        'Perl::Critic::Tics',
    );

    return sub {
        return if !@stack;
        return shift @stack;
    };
}

# Returns an iterator that iterates over all policies of all the perlcritic
# policy distributions we use. Return value is an array ref of the
# distribution name and the policy name.
sub _perl_critic_policy {
    my ($self) = @_;

    my $dist_it = $self->_perl_critic_policy_distributions();
    my $dist;
    my $pol_it;

    return sub {
        if ( defined $pol_it ) {
            my $pol = $pol_it->();
            return [ $dist, $pol ] if defined $pol;
        }

        $dist = $dist_it->();
        return if !defined $dist;

        $pol_it = $self->_perl_critic_policy_from_distribution($dist);
        my $pol = $pol_it->();
        return [ $dist, $pol ] if defined $pol;
        return;
    };
}

# Returns an iterator that iterates over all policies of all the perlcritic
# policy distributions we use. Return value is an array ref of the
# distribution name, the policy name and if the policy should be enabled.
#
# This method has a blacklist of policies we don't like. They get disabled.
#
# This method has another blacklist of policies that are no policies,
# basically badly named packages. They get completely dropped.
sub _perl_critic_policy_default_enabled {
    my ($self) = @_;

    my %disabled_policies = map { $_ => 0 } (

        # core policies
        'CodeLayout::RequireTidyCode',
        'Documentation::PodSpelling',
        'Documentation::RequirePodSections',
        'InputOutput::RequireBriefOpen',
        'Modules::ProhibitExcessMainComplexity',
        'Modules::RequireVersionVar',
        'RegularExpressions::ProhibitComplexRegexes',
        'RegularExpressions::ProhibitEnumeratedClasses',
        'ValuesAndExpressions::ProhibitMagicNumbers',

        # Perl::Critic::Bangs
        'Bangs::ProhibitCommentedOutCode',
        'Bangs::ProhibitNoPlan',
        'Bangs::ProhibitVagueNames',

        # Perl::Critic::Freenode
        'Freenode::EmptyReturn',

        # Perl::Critic::Itch
        'CodeLayout::ProhibitHashBarewords',

        # Perl::Critic::Lax
        'Lax::ProhibitEmptyQuotes::ExceptAsFallback',
        'Lax::ProhibitLeadingZeros::ExceptChmod',
        'Lax::ProhibitStringyEval::ExceptForRequire',
        'Lax::RequireConstantOnLeftSideOfEquality::ExceptEq',
        'Lax::RequireEndWithTrueConst',
        'Lax::RequireExplicitPackage::ExceptForPragmata',

        # Perl::Critic::More
        'CodeLayout::RequireASCII',
        'Editor::RequireEmacsFileVariables',
        'ErrorHandling::RequireUseOfExceptions',
        'ValuesAndExpressions::RequireConstantOnLeftSideOfEquality',
        'ValuesAndExpressions::RestrictLongStrings',

        # Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice
        # (requires Perl 5.12)
        'ValuesAndExpressions::ProhibitSingleArgArraySlice',

        # Perl::Critic::Pulp
        'CodeLayout::ProhibitIfIfSameLine',
        'Compatibility::Gtk2Constants',
        'Compatibility::PodMinimumVersion',
        'Documentation::ProhibitDuplicateSeeAlso',
        'Documentation::RequireFinalCut',
        'Miscellanea::TextDomainPlaceholders',
        'Miscellanea::TextDomainUnused',
        'ValuesAndExpressions::ProhibitFiletest_f',

        # Perl::Critic::StricterSubs
        'Subroutines::ProhibitCallsToUndeclaredSubs',
        'Subroutines::ProhibitCallsToUnexportedSubs',

        # Perl::Critic::Tics
        'Tics::ProhibitLongLines',
    );

    my %policies_to_remove = map { $_ => 1 } (

        # This is no policy, just a badly named package!
        'Documentation::ProhibitAdjacentLinks::Parser',
    );

    my $it = $self->_perl_critic_policy();

    return sub {
        my $pol_ref;

      POL_REF:
        while (1) {
            $pol_ref = $it->();
            last POL_REF if !defined $pol_ref;
            last POL_REF if !exists $policies_to_remove{ $pol_ref->[1] };
        }

        if ( !defined $pol_ref ) {
          POLICY:
            for my $policy ( keys %disabled_policies ) {
                next POLICY if $disabled_policies{$policy} == 1;

                $self->log_fatal("Policy '$policy' is disabled but does not exist.");
            }

            return;
        }

        push @{$pol_ref}, exists $disabled_policies{ $pol_ref->[1] } ? 0 : 1;
        $disabled_policies{ $pol_ref->[1] } = 1;

        return $pol_ref;
    };
}

# Returns an iterator that iterates over all policies of all the perlcritic
# policy distributions we use. Return value is an array ref of the
# distribution name, the policy name, if the policy should be enabled and
# either undef or a hash ref of default configuration for that policy.
#
# This method contains a list a default configurations we like.
sub _perl_critic_policy_default_config {
    my ($self) = @_;

    my $it = $self->_perl_critic_policy_default_enabled();

    return sub {
        my $pol_ref = $it->();
        return if !defined $pol_ref;

        my $policy = $pol_ref->[1];

        push @{$pol_ref},

          # Core Policies
            $policy eq 'ErrorHandling::RequireCarping' ? { allow_in_main_unless_in_subroutine => '1' }
          : $policy eq 'InputOutput::RequireCheckedSyscalls' ? { functions => ':builtins', exclude_functions => 'print say sleep' }
          : $policy eq 'Modules::ProhibitEvilModules' ? { modules => 'Class::ISA {Found use of Class::ISA. This module is deprecated by the Perl 5 Porters.} Pod::Plainer {Found use of Pod::Plainer. This module is deprecated by the Perl 5 Porters.} Shell {Found use of Shell. This module is deprecated by the Perl 5 Porters.} Switch {Found use of Switch. This module is deprecated by the Perl 5 Porters.} Readonly {Found use of Readonly. Please use constant.pm or Const::Fast.} base {Found use of base. Please use parent instead.} File::Slurp {Found use of File::Slurp. Please use Path::Tiny instead.} common::sense {Found use of common::sense. Please use strict and warnings instead.} Class::Load {Found use of Class::Load. Please use Module::Runtime instead.} Any::Moose {Found use of Any::Moose. Please use Moo instead.} Error {Found use of Error.pm. Please use Throwable.pm instead.} Getopt::Std {Found use of Getopt::Std. Please use Getopt::Long instead.} HTML::Template {Found use of HTML::Template. Please use Template::Toolkit.} IO::Socket::INET6 {Found use of IO::Socket::INET6. Please use IO::Socket::IP.} JSON {Found use of JSON. Please use JSON::MaybeXS or Cpanel::JSON::XS.} JSON::XS {Found use of JSON::XS. Please use JSON::MaybeXS or Cpanel::JSON::XS.} JSON::Any {Found use of JSON::Any. Please use JSON::MaybeXS.} List::MoreUtils {Found use of List::MoreUtils. Please use List::Util or List::UtilsBy.} Mouse {Found use of Mouse. Please use Moo.} Net::IRC {Found use of Net::IRC. Please use POE::Component::IRC, Net::Async::IRC, or Mojo::IRC.} XML::Simple {Found use of XML::Simple. Please use XML::LibXML, XML::TreeBuilder, XML::Twig, or Mojo::DOM.} Sub::Infix {Found use of Sub::Infix. Please do not use it.} vars {the vers pragma has been superseded by our declarations, available in Perl v5.6.0 or later, and use of this pragma is discouraged.}' }
          : $policy eq 'Subroutines::ProhibitUnusedPrivateSubroutines' ? { private_name_regex => '_(?!build_)\w+' }
          : $policy eq 'ValuesAndExpressions::ProhibitComplexVersion'  ? { forbid_use_version => '1' }
          : $policy eq 'Variables::ProhibitPunctuationVars'            ? { allow              => '$@ $! $/ $0' }      ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)

          # Perl::Critic::Moose
          : $policy eq 'Moose::ProhibitDESTROYMethod' ? { equivalent_modules => 'Moo Moo::Role' }
          : $policy eq 'Moose::ProhibitLazyBuild'     ? { equivalent_modules => 'Moo Moo::Role' }
          : $policy eq 'Moose::ProhibitMultipleWiths' ? { equivalent_modules => 'Moo Moo::Role' }
          : $policy eq 'Moose::ProhibitNewMethod'     ? { equivalent_modules => 'Moo Moo::Role' }

          # Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter
          : $policy eq 'Variables::ProhibitUnusedVarsStricter' ? { allow_unused_subroutine_arguments => '1' }
          :                                                      undef;

        return $pol_ref;
    };
}

# Parses the perlcriticrc-*.local configuration file. Then, returns an
# iterator that iterates over all policies of all the perlcritic policy
# distributions we use. Return value is an array ref of the distribution
# name, the policy name, if the policy should be enabled and either undef
# or a hash ref of configuration for that policy.
sub _perl_critic_policy_with_config {
    my ( $self, $perlcriticrc_local ) = @_;

    my $it = $self->_perl_critic_policy_default_config();

    my %local_config;

    if ( -f $perlcriticrc_local ) {
        $self->log("Adjusting Perl::Critic config from '$perlcriticrc_local'");

        read_config $perlcriticrc_local, my %perlcriticrc_local;

        my %local_seen;

      POLICY:
        for my $policy ( keys %perlcriticrc_local ) {

            $self->log_fatal('We cannot disable the global settings') if $policy eq q{-};

            my $policy_name = $policy =~ m{ ^ - (.+) }xsm ? $1 : $policy;

            $self->log_fatal("There are multiple entries for policy '$policy_name' in '$perlcriticrc_local'.") if exists $local_seen{$policy_name};

            $local_seen{$policy_name} = 1;

            if ( $policy =~ m{ ^ - }xsm ) {
                $self->log_debug("Disabling policy '$policy_name'");
                $local_config{$policy_name} = [0];
                next POLICY;
            }
            #
            $self->log_fatal('Custom global settings are not supported') if $policy eq q{};

            $self->log_debug("Custom configuration for policy '$policy_name'");
            $local_config{$policy} = [ 1, $perlcriticrc_local{$policy_name} ];
        }
    }

    my %local_config_unused = map { $_ => 1 } keys %local_config;
    return sub {
        my $pol_ref = $it->();

        if ( !defined $pol_ref ) {
            my ($first_not_used_policy_from_local_config) = keys %local_config_unused;
            $self->log_fatal("Policy '$first_not_used_policy_from_local_config' is mentioned the local configuration file '$perlcriticrc_local' but does not exist.") if defined $first_not_used_policy_from_local_config;

            return;
        }

        my ( $dist, $policy, $enabled_default, $config_default_ref ) = @{$pol_ref};
        return $pol_ref if !exists $local_config{$policy};

        delete $local_config_unused{$policy};

        # policy is disabled from local config
        return [ $dist, $policy, 0, undef ] if ${ $local_config{$policy} }[0] == 0;

        # policy is enabled from local config, with no local configuration
        return [ $dist, $policy, 1, undef ] if ( @{ $local_config{$policy} } == 1 ) || ( scalar keys %{ ${ $local_config{$policy} }[1] } == 0 );

        # policy is enabled from local config, with local configuration
        return [ $dist, $policy, 1, ${ $local_config{$policy} }[1] ];
    };
}

# Returns an iterator that iterates over all policies of all the perlcritic
# policy distributions we use. Return value is a string containing the
# configuration of one policy, or a comment block.
#
# The returned string are expected to be concatenated together to create
# the .perlcriticrc config file.
sub _perl_critic_config_block {
    my ( $self, $perlcriticrc_local ) = @_;

    my $it = $self->_perl_critic_policy_with_config($perlcriticrc_local);

    my $last_dist = q{};
    my $pol_ref;
    my $empty_line = 0;
    return sub {
        if ( !defined $pol_ref ) {
            $pol_ref = $it->();
        }

        return if !defined $pol_ref;

        my ( $dist, $policy, $enabled, $config_ref ) = @{$pol_ref};

        if ( $dist ne $last_dist ) {

            # we have to return the dist "header"
            $last_dist = $dist;

            my $result = $empty_line ? q{} : "\n";
            $result .= '# ' . ( q{-} x 58 ) . "\n";
            $result .= ( $dist eq 'Perl::Critic' ? "# Core policies\n" : "# $dist\n" );
            $result .= '# ' . ( q{-} x 58 ) . "\n\n";

            $empty_line = 1;

            return $result;
        }

        $pol_ref = undef;

        my $result = "[$policy]\n";

        if ( !$enabled ) {
            $empty_line = 0;
            return "#$result";
        }

        if ( !defined $config_ref ) {
            $empty_line = 0;
            return $result;
        }

        if ( !$empty_line ) {
            $result = "\n$result";
        }

        for my $key ( sort keys %{$config_ref} ) {
            $result .= "$key = ${$config_ref}{$key}\n";
        }

        $empty_line = 1;
        return "$result\n";

    };
}

# Returns a string containing the content of a .perlcriticrc config file
# based on the local configuration file and defaults saved in this module.
sub _perlcriticrc {
    my ( $self, $perlcriticrc_local ) = @_;

    my $content = <<'PERLCRITICRC_TEMPLATE';
# {{ $plugin->_generated_string() }}

only = 1
profile-strictness = fatal
severity = 1
verbose = [%p] %m at %f line %l, near '%r'\n
PERLCRITICRC_TEMPLATE

    my $it = $self->_perl_critic_config_block($perlcriticrc_local);

    while ( defined( my $x = $it->() ) ) {
        $content .= $x;
    }

    return $content;
}

sub _relevant_perl_5_8_versions {
    my ($self) = @_;

    my $earliest_perl = $self->ci_earliest_perl;
    return if version->parse("v$earliest_perl") >= version->parse('v5.9');

    $self->log_fatal('Perl 5.8.0 is not supported because cpanm does not work on 5.8.0') if $earliest_perl eq '5.8.0';
    $self->log_fatal("Perl $earliest_perl does not exist") if version->parse("v$earliest_perl") > version->parse('v5.8.9');

    return qw(5.8.1 5.8.2 5.8) if $earliest_perl eq '5.8' || $earliest_perl eq '5.8.1';
    return $earliest_perl, '5.8' if version->parse("v$earliest_perl") < version->parse('v5.8.8');

    return $earliest_perl;
}

sub _relevant_perl_5_10_versions {
    my ($self) = @_;

    my $earliest_perl = $self->ci_earliest_perl;
    return if version->parse("v$earliest_perl") >= version->parse('v5.11');

    $self->log_fatal("Perl $earliest_perl does not exist") if version->parse("v$earliest_perl") > version->parse('v5.10.1');

    return '5.10' if $earliest_perl eq '5.10.1';
    return qw(5.10.0 5.10);
}

# This generates a list of Perl versions I think are relevant to be tested on
# Travis CI. The list includes all stable versions of Perl, starting with
# 5.8, as major.minor entry. Additionally, the following versions are added:
#  - 5.8.0
#  - 5.8.1
#  - 5.8.2
#  - 5.10.0
sub _relevant_perl_versions {
    my ($self) = @_;

    my $earliest_perl = $self->ci_earliest_perl;

    # Generate the list of all stable versions of perl as major.minor,
    # starting with 5.12 (or the first version we are interested in).
    my %perl;
  PERL:
    for my $perl ( perl_versions() ) {
        next PERL if $perl !~ m { ^ 5 [.] ( [1-9][0-9]* ) [.] [0-9]+ $ }xsm;
        my $minor = $1;    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)

        # Remove dev releases
        next PERL if $minor % 2;

        next PERL if version->parse("v5.$minor") < version->parse("v$earliest_perl");
        next PERL if $minor < 12;

        $perl{$minor} = 1;
    }

    my @perls;

    if ( version->parse("v$earliest_perl") < version->parse('v5.11') ) {
        if ( version->parse("v$earliest_perl") < version->parse('v5.9') ) {
            @perls = $self->_relevant_perl_5_8_versions;
        }

        push @perls, $self->_relevant_perl_5_10_versions;
    }
    elsif ( $earliest_perl =~ m{ ^ 5 [.] ( [1-9][0-9]* ) [.] ( [0-9]+ ) $ }xsm ) {

        # if the earliest perl version has a patch level, add this version to
        # the versions to be tested but skip the major.minor from Travis for
        # this release. The _relevant_perl_5_8_versions and
        # _relevant_perl_5_10_versionsal method already does that for these releases.

        @perls = "5.$1.$2";
    }

    # Add the releases >= 5.12 releases
    push @perls, map { "5.$_" } sort { $a <=> $b } keys %perl;

    return @perls;
}

sub _build_strawberry_releases {
    my ($self) = @_;

    my $url = 'http://strawberryperl.com/releases.json';
    $self->log_debug("Downloading '$url'...");
    my $res = $self->ua->get($url);

    $self->log_fatal("Cannot download '$url': $res->{reason}") if !$res->{success};

    my @releases;

  RELEASE:
    for my $release ( @{ decode_json( $res->{content} ) } ) {
        my $version = $release->{version};
        ## no critic (RegularExpressions::RequireDotMatchAnything)
        ## no critic (RegularExpressions::RequireExtendedFormatting)
        ## no critic (RegularExpressions::RequireLineBoundaryMatching)
        my @name = split /\s*\/\s*/, $release->{name};

        $self->log_fatal("Unable to parse name: $release->{name}") if ( @name < 3 ) || ( @name > 4 );
        $self->log_fatal("Version '$version' does not version in name '$name[1]'") if $version ne $name[1];
        $self->log_fatal("Unable to parse version '$version'") if $version !~ m{ ^ ( ( 5 [.] [1-9][0-9]* ) [.] [0-9]+ ) [.] [0-9]+ $ }xsm;

        my @release = ( $2, $1, $version );    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)

        next RELEASE if !exists $release->{edition}->{zip}->{url};
        push @release, $release->{edition}->{zip}->{url};

        if ( $name[2] eq '64bit' ) {
            push @release, $name[2];
        }
        elsif ( $name[2] eq '32bit' ) {
            push @release, $name[2];

            if ( $name[3] eq 'with USE_64_BIT_INT' ) {
                push @release, WITH_USE_64_BIT_INT;
            }
            elsif ( $name[3] eq 'without USE_64_BIT_INT' ) {
                push @release, WITHOUT_USE_64_BIT_INT;
            }
            else {
                $self->log_fatal("Expect either 'with USE_64_BIT_INT' or 'without USE_64_BIT_INT' but got '$name[3]'");
            }
        }
        else {
            $self->log_fatal("Expected either 32bit or 64bit but got '$name[2]'");
        }

        push @releases, \@release;
    }

    return \@releases;
}

sub _relevant_strawberry_perl_versions_sort {
    my $x = version->parse("v$a->[2]") <=> version->parse("v$b->[2]");
    return $x if $x;

    if ( $a->[4] ne $b->[4] ) {
        return 1 if $a->[4] eq '64bit';
        return -1;
    }

    return $a->[5] <=> $b->[5];
}

sub _relevant_strawberry_perl_versions {
    my ($self) = @_;

    my $earliest_perl = version->parse( 'v' . $self->appveyor_earliest_perl );
    my @strawberry_releases =
      reverse
      sort _relevant_strawberry_perl_versions_sort grep { version->parse("v$_->[1]") >= $earliest_perl } @{ $self->_strawberry_releases() };

    my @strawberry_releases_to_use;
    my %perl_configured;
  RELEASE:
    for my $strawberry_ref (@strawberry_releases) {
        if ( $strawberry_ref->[0] eq '5.10' ) {
            next RELEASE if exists $perl_configured{ $strawberry_ref->[1] };
            $perl_configured{ $strawberry_ref->[1] } = 1;
        }
        else {
            next RELEASE if exists $perl_configured{ $strawberry_ref->[0] };
            $perl_configured{ $strawberry_ref->[0] } = 1;
        }

        push @strawberry_releases_to_use, $strawberry_ref;
    }

    return reverse map { [ $_->[1], $_->[3] ] } @strawberry_releases_to_use;
}

{
    # Files to generate
    my %file;

    sub files {
        my ($self) = @_;

        return keys %file;
    }

    sub file {
        my ( $self, $filename ) = @_;

        $self->log_fatal("File '$filename' is not defined") if !exists $file{$filename};

        my $file_content = $file{$filename};
        if ( ref $file_content eq ref sub { } ) {
            $file_content = $file_content->($self);
        }

        # process the file template
        return $self->fill_in_string(
            $file_content,
            {
                plugin => \$self,
            },
        );
    }

=head2 .appveyor.yml

The configuration file for AppVeyor.

=cut

    $file{q{.appveyor.yml}} = sub {
        my ($self) = @_;

        # https://github.com/rjbs/Data-UUID/issues/24
        # Create the c:\tmp directory because Data::UUID can't be built on
        # Windows without it.

        my $appveyor_yml = <<'APPVEYOR_YML';
# {{ $plugin->_generated_string() }}

skip_tags: true

environment:
  AUTOMATED_TESTING: 1
  TAR_OPTIONS: --warning=no-unknown-keyword

  matrix:
APPVEYOR_YML

        my %latest_dzil_release = %{ $self->_latest_dist_zilla_releases };

        my $dzil_used          = $self->ci_dist_zilla;
        my $appveyor_perl_used = 0;

        if ( $self->appveyor_test_on_cygwin ) {
            $appveyor_perl_used = 1;
            $appveyor_yml .= <<'APPVEYOR_YML';
    - PERL_TYPE: cygwin
      AUTHOR_TESTING: 1
APPVEYOR_YML

            if ($dzil_used) {
                $appveyor_yml .= "      DIST_ZILLA: $latest_dzil_release{6}\n";
            }

            $appveyor_yml .= "\n";
        }

        if ( $self->appveyor_test_on_cygwin64 ) {
            $appveyor_perl_used = 1;
            $appveyor_yml .= <<'APPVEYOR_YML';
    - PERL_TYPE: cygwin64
      AUTHOR_TESTING: 1
APPVEYOR_YML

            if ($dzil_used) {
                $appveyor_yml .= "      DIST_ZILLA: $latest_dzil_release{6}\n";
            }

            $appveyor_yml .= "\n";
        }

        if ( $self->appveyor_test_on_strawberry ) {

            ## no critic (RegularExpressions::RequireDotMatchAnything)
            ## no critic (RegularExpressions::RequireExtendedFormatting)
            ## no critic (RegularExpressions::RequireLineBoundaryMatching)
            my $auth_regex = join q{|}, map { qr{^\Q$_\E(?:[.].+)?$} } @{ $self->appveyor_author_testing_perl };

            for my $strawberry_ref ( $self->_relevant_strawberry_perl_versions ) {
                $appveyor_perl_used = 1;
                my ( $perl, $url ) = @{$strawberry_ref};

                $appveyor_yml .= <<"APPVEYOR_YML";
    - PERL_TYPE: strawberry
      PERL_VERSION: $perl
APPVEYOR_YML
                if ($dzil_used) {
                    if ( version->parse("v$perl") < version->parse(DZIL_6_NEEDS_PERL) ) {
                        $appveyor_yml .= "      DIST_ZILLA: $latest_dzil_release{5}\n";
                    }
                    else {
                        $appveyor_yml .= "      DIST_ZILLA: $latest_dzil_release{6}\n";
                    }
                }

                if ( $perl =~ $auth_regex ) {
                    $appveyor_yml .= "      AUTHOR_TESTING: 1\n";
                }

                $appveyor_yml .= "      STRAWBERRY_URL: $url\n";
                $appveyor_yml .= "\n";
            }
        }

        $self->log_fatal('No Perl enabled for AppVeyor') if !$appveyor_perl_used;

        $appveyor_yml .= <<'APPVEYOR_YML';
install:
  - ps: 'Write-Host "ERROR: Unknown Perl type ''$env:PERL_TYPE''"'
  - exit 1

for:
APPVEYOR_YML

        if ( $self->appveyor_test_on_cygwin ) {
            $appveyor_yml .= <<'APPVEYOR_YML';
  -
    matrix:
      only:
        - PERL_TYPE: cygwin

    install:
      - c:\cygwin\setup-x86.exe -q -C devel -C perl -P libcrypt-devel -P openssl-devel
      - set PATH=C:\cygwin\bin;C:\cygwin\usr\local\bin;%PATH%

APPVEYOR_YML
        }

        if ( $self->appveyor_test_on_cygwin64 ) {
            $appveyor_yml .= <<'APPVEYOR_YML';
  -
    matrix:
      only:
        - PERL_TYPE: cygwin64

    install:
      - c:\cygwin64\setup-x86_64.exe -q -C devel -C perl -P libcrypt-devel -P openssl-devel
      - set PATH=C:\cygwin64\bin;C:\cygwin64\usr\local\bin;%PATH%

APPVEYOR_YML
        }

        if ( $self->appveyor_test_on_strawberry ) {
            $appveyor_yml .= <<'APPVEYOR_YML';
  -
    matrix:
      only:
        - PERL_TYPE: strawberry

    install:
      - ps: Invoke-WebRequest $env:STRAWBERRY_URL -OutFile strawberry.zip
      - ps: Expand-Archive strawberry.zip -DestinationPath c:\Strawberry
      - if exist c:\Strawberry\relocation.pl.bat c:\Strawberry\relocation.pl.bat
      - erase strawberry.zip
      - set PATH=C:\Strawberry\perl\site\bin;C:\Strawberry\perl\bin;C:\Strawberry\c\bin;%PATH%

APPVEYOR_YML
        }

        $appveyor_yml .= <<'APPVEYOR_YML';
before_build:
  - mv c:\mingw-w64 c:\mingw-w64.old
  - mv c:\mingw c:\mingw.old
  - ps: systeminfo | Select-String "^OS Name", "^OS Version"
  - where perl
  - perl -V
  - ps: Invoke-WebRequest https://raw.githubusercontent.com/skirmess/dzil-inc/master/bin/check-ci-perl-version -OutFile check-ci-perl-version.pl
  - perl check-ci-perl-version.pl --appveyor
  - erase check-ci-perl-version.pl
  - ps: $env:make = perl -MConfig -e'print $Config{make}'
  - echo %make%
  - if not exist %make% where %make%
  - where gcc
  - gcc --version
  - where g++
  - g++ --version
  - ps: Invoke-WebRequest https://cpanmin.us/ -OutFile cpanm.pl
  - perl cpanm.pl App::cpanminus
  - erase cpanm.pl
  - where cpanm
  - perl -S cpanm --version
  - mkdir C:\tmp
APPVEYOR_YML

        if ( $self->ci_dist_zilla ) {
            $appveyor_yml .= <<'APPVEYOR_YML';
  - if     defined DIST_ZILLA     perl -S cpanm --verbose --notest --skip-satisfied Dist::Zilla@%DIST_ZILLA%
  - if     defined DIST_ZILLA     perl -S dzil version
APPVEYOR_YML
        }

        $appveyor_yml .= <<'APPVEYOR_YML';
  - if     defined AUTHOR_TESTING perl -S cpanm --verbose --installdeps --notest --skip-satisfied --with-develop .
  - if not defined AUTHOR_TESTING perl -S cpanm --verbose --installdeps --notest --skip-satisfied .
  - perl -S cpanm --verbose --notest --skip-satisfied App::ReportPrereqs
  - if     defined AUTHOR_TESTING perl -S report-prereqs --with-develop
  - if not defined AUTHOR_TESTING perl -S report-prereqs

build_script:
  - set PERL_USE_UNSAFE_INC=0
APPVEYOR_YML

        if ( $self->makefile_pl_exists() ) {
            $appveyor_yml .= <<'APPVEYOR_YML';
  - perl Makefile.PL
  - '%make%'
APPVEYOR_YML
        }

        $appveyor_yml .= <<'APPVEYOR_YML';

test_script:
APPVEYOR_YML

        $appveyor_yml .= $self->makefile_pl_exists()
          ? <<'APPVEYOR_YML'
  - '%make% test'
APPVEYOR_YML
          : <<'APPVEYOR_YML';
  - prove -lr t
APPVEYOR_YML

        $appveyor_yml .= <<'APPVEYOR_YML';
  - if defined AUTHOR_TESTING perl -S prove -lr xt/author
APPVEYOR_YML

        return $appveyor_yml;
    };

=head2 .perltidyrc

The configuration file for B<perltidy>.

=cut

    $file{q{.perltidyrc}} = <<'PERLTIDYRC';
# {{ $plugin->_generated_string() }}

--maximum-line-length=0
--break-at-old-comma-breakpoints
--backup-and-modify-in-place
--output-line-ending=unix
PERLTIDYRC

=head2 .travis.yml

The configuration file for TravisCI. All known supported Perl versions are
enabled unless they are older then B<ci_earliest_perl>.

With B<travis_ci_osx_perl> you can specify one or multiple Perl versions to
be tested on OSX, in addition to on Linux. If omitted it defaults to one
single version.

Use the B<travis_ci_author_testing_perl> option to enable author tests on
specific Perl versions. By default it is only enabled on one version.
Additionally, author testing is enabled on the osx run.

=cut

    $file{q{.travis.yml}} = sub {
        my ($self) = @_;

        my $travis_yml = <<'TRAVIS_YML';
# {{ $plugin->_generated_string() }}

language: perl

cache:
  directories:
    - ~/perl5

env:
  global:
    - AUTOMATED_TESTING=1
    - TAR_OPTIONS=--warning=no-unknown-keyword

git:
  submodules: false

matrix:
  include:
TRAVIS_YML

        my %auth;
        @auth{ @{ $self->travis_ci_author_testing_perl } } = ();

        my %osx_perl;
        @osx_perl{ @{ $self->travis_ci_osx_perl } } = ();

        my $dzil_used = $self->ci_dist_zilla;

        my $perl_helper_used = 0;

        my %latest_dzil_release = %{ $self->_latest_dist_zilla_releases };

      PERL:
        for my $perl ( $self->_relevant_perl_versions ) {
            my @os = (undef);
            if ( exists $osx_perl{$perl} ) {
                push @os, 'osx';
            }

            for my $os (@os) {
                $travis_yml .= "    - perl: '$perl'\n";

                if ( $perl =~ m{ ^ 5 [.] ( [1-9][0-9]* ) [.] ( [0-9]+ ) $ }xsm ) {
                    $perl_helper_used = 1;
                }

                my @env;

                if ($dzil_used) {
                    $self->log_fatal('I cannot install Dist::Zilla on Perl below 5.8.8 (because Net::SSLeay fails to install)') if version->parse("v$perl") < version->parse('v5.8.8');

                    if ( version->parse("v$perl") < version->parse(DZIL_6_NEEDS_PERL) ) {
                        push @env, "DIST_ZILLA=$latest_dzil_release{5}";
                    }
                    else {
                        push @env, "DIST_ZILLA=$latest_dzil_release{6}";
                    }
                }

                if ( ( exists $auth{$perl} ) or ( defined $os ) ) {
                    push @env, 'AUTHOR_TESTING=1';
                }

                if (@env) {
                    $travis_yml .= '      env: ' . join( q{ }, @env ) . "\n";
                }

                if ( defined $os ) {
                    $travis_yml .= "      os: $os\n";
                }

                $travis_yml .= "\n";
            }
        }

        $travis_yml .= <<'TRAVIS_YML';
before_install:
  - |
    case "${TRAVIS_OS_NAME}" in
      "linux" )
        ;;
      "osx"   )
        # TravisCI extracts the broken perl archive with sudo which creates the
        # $HOME/perl5 directory with owner root:staff. Subdirectories under
        # perl5 are owned by user travis.
        sudo chown "$USER" "$HOME/perl5"

        # The perl distribution TravisCI extracts on OSX is incomplete
        sudo rm -rf "$HOME/perl5/perlbrew"

        # Install cpanm and local::lib
        curl -L https://cpanmin.us | perl - App::cpanminus local::lib
        eval $(perl -I $HOME/perl5/lib/perl5/ -Mlocal::lib)
        ;;
    esac
TRAVIS_YML

        if ($perl_helper_used) {
            $travis_yml .= <<'TRAVIS_YML';
  - |
    if [[ $TRAVIS_PERL_VERSION =~ 5[.][1-9][0-9]*[.][0-9][0-9]* ]]
    then
        echo "Initializing the Travis Perl Helper"

        if [ -z "$AUTHOR_TESTING" ]
        then
            AUTHOR_TESTING=0
        fi

        git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
        source ~/travis-perl-helpers/init
        build-perl

        if [ "$AUTHOR_TESTING" = 0 ]
        then
            unset AUTHOR_TESTING
        fi
    fi
TRAVIS_YML

        }

        $travis_yml .= <<'TRAVIS_YML';
  - which perl
  - perl -V
  - curl -L https://raw.githubusercontent.com/skirmess/dzil-inc/master/bin/check-ci-perl-version | perl - --travis
  - which make
  - which gcc
  - gcc --version
  - which cpanm
  - cpanm --version

install:
TRAVIS_YML

        if ($dzil_used) {
            $travis_yml .= <<'TRAVIS_YML';
  - |
    if [ -n "$DIST_ZILLA" ]
    then
        cpanm --verbose --notest --skip-satisfied Dist::Zilla@$DIST_ZILLA
        dzil version
    fi
TRAVIS_YML

        }

        $travis_yml .= <<'TRAVIS_YML';
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
        cpanm --verbose --installdeps --notest --skip-satisfied --with-develop .
    else
        cpanm --verbose --installdeps --notest --skip-satisfied .
    fi
  - cpanm --verbose --notest --skip-satisfied App::ReportPrereqs
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
        report-prereqs --with-develop
    else
        report-prereqs
    fi

script:
  - PERL_USE_UNSAFE_INC=0
TRAVIS_YML

        $travis_yml .=
          $self->makefile_pl_exists()
          ? "  - perl Makefile.PL && make test\n"
          : "  - prove -lr t\n";

        $travis_yml .= <<'TRAVIS_YML';
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
        prove -lr xt/author
    fi
TRAVIS_YML

        return $travis_yml;
    };

    # test header
    my $test_header = <<'_TEST_HEADER';
#!perl

use 5.006;
use strict;
use warnings;

# {{ $plugin->_generated_string() }}

_TEST_HEADER

=head2 xt/author/clean-namespaces.t

L<Test::CleanNamespaces|Test::CleanNamespaces> author test.

=cut

    $file{q{xt/author/clean-namespaces.t}} = $test_header . <<'XT_AUTHOR_CLEAN_NAMESPACES_T';
use Test::More;
use Test::CleanNamespaces;

if ( !Test::CleanNamespaces->find_modules() ) {
    plan skip_all => 'No files found to test.';
}

all_namespaces_clean();
XT_AUTHOR_CLEAN_NAMESPACES_T

=head2 xt/author/minimum_version.t

L<Test::MinimumVersion|Test::MinimumVersion> author test.

=cut

    $file{q{xt/author/minimum_version.t}} = $test_header . <<'XT_AUTHOR_MINIMUM_VERSION_T';
use Test::MinimumVersion 0.008;

all_minimum_version_from_metayml_ok();
XT_AUTHOR_MINIMUM_VERSION_T

=head2 xt/author/mojibake.t

L<Test::Mojibake|Test::Mojibake> author test.

=cut

    $file{q{xt/author/mojibake.t}} = $test_header . <<'XT_AUTHOR_MOJIBAKE_T';
use Test::Mojibake;

all_files_encoding_ok( grep { -d } qw( bin lib t xt ) );
XT_AUTHOR_MOJIBAKE_T

=head2 xt/author/no-tabs.t

L<Test::NoTabs|Test::NoTabs> author test.

=cut

    $file{q{xt/author/no-tabs.t}} = $test_header . <<'XT_AUTHOR_NO_TABS_T';
use Test::NoTabs;

all_perl_files_ok( grep { -d } qw( bin lib t xt ) );
XT_AUTHOR_NO_TABS_T

=head2 xt/author/perlcriticrc-code

The configuration for L<Perl::Critic|Perl::Critic> for F<bin> and F<lib>.
This file is created from a default contained in this plugin and, if it
exists from distribution specific settings in F<perlcriticrc-code.local>.

=cut

    $file{q{xt/author/perlcriticrc-code}} = sub {
        my ($self) = @_;

        return $self->_perlcriticrc('perlcriticrc-code.local');
    };

=head2 xt/author/perlcriticrc-tests

The configuration for L<Perl::Critic|Perl::Critic> for F<t> and F<xt>.
This file is created from a default contained in this plugin and, if it
exists from distribution specific settings in F<perlcriticrc-tests.local>.

=cut

    $file{q{xt/author/perlcriticrc-tests}} = sub {
        my ($self) = @_;

        return $self->_perlcriticrc('perlcriticrc-tests.local');
    };

=head2 xt/author/perlcritic-code.t

L<Test::Perl::Critic|Test::Perl::Critic> author test for F<bin> and F<lib>.

=cut

    $file{q{xt/author/perlcritic-code.t}} = $test_header . <<'XT_AUTHOR_PERLCRITIC_CODE_T';
use FindBin qw($RealBin);
use Test::Perl::Critic ( -profile => "$RealBin/perlcriticrc-code" );

all_critic_ok(qw(bin lib));
XT_AUTHOR_PERLCRITIC_CODE_T

=head2 xt/author/perlcritic-tests.t

L<Test::Perl::Critic|Test::Perl::Critic> author test for F<t> and F<xt>.

=cut

    $file{q{xt/author/perlcritic-tests.t}} = $test_header . <<'XT_AUTHOR_PERLCRITIC_TESTS_T';
use FindBin qw($RealBin);
use Test::Perl::Critic ( -profile => "$RealBin/perlcriticrc-tests" );

all_critic_ok(qw(t xt));
XT_AUTHOR_PERLCRITIC_TESTS_T

=head2 xt/author/perltidy.t

L<Test::PerlTidy|Test::PerlTidy> author test.

=cut

    $file{q{xt/author/perltidy.t}} = $test_header . <<'XT_AUTHOR_PERLCRITIC_TESTS_T';
use FindBin qw($RealBin);
use Path::Tiny;
use Test::More;
use Test::PerlTidy;

my @files;
if ( -d 'bin' ) {
    my $it = path('bin')->iterator( { recurse => 1 } );

  BIN:
    while ( defined( my $file = $it->() ) ) {
        next BIN if !-f $file;

        push @files, $file->stringify;
    }
}

if ( -d 'lib' ) {
    my $it = path('lib')->iterator( { recurse => 1 } );

  LIB:
    while ( defined( my $file = $it->() ) ) {
        next LIB if !-f $file;
        next LIB if $file !~ m{ [.] pm $ }xsm;

        push @files, $file->stringify;
    }
}

for my $dir (qw(t xt)) {
    my $it = path($dir)->iterator( { recurse => 1 } );

  TEST:
    while ( defined( my $file = $it->() ) ) {
        next TEST if !-f $file;
        next TEST if $file !~ m{ [.] t $ }xsm && $file !~ m{ ^ t/lib/ .* [.] pm $ }xsm;

        push @files, $file->stringify;
    }
}

if ( !@files ) {
    plan skip_all => 'No files found to test.';
}

plan tests => scalar @files;

my $perltidyrc = path($RealBin)->parent(2)->child('.perltidyrc')->stringify;

$Test::PerlTidy::MUTE = 1;

for my $file (@files) {
    ok( Test::PerlTidy::is_file_tidy( $file, $perltidyrc ), $file );
}
XT_AUTHOR_PERLCRITIC_TESTS_T

=head2 xt/author/pod-linkcheck.t

L<Test::Pod::LinkCheck|Test::Pod::LinkCheck> author test.

=cut

    $file{q{xt/author/pod-linkcheck.t}} = $test_header . <<'XT_AUTHOR_POD_LINKCHECK_T';
# CPANPLUS is used by Test::Pod::LinkCheck but is not a dependency. The
# require on CPANPLUS is only here for dzil to pick it up and add it as a
# develop dependency to the cpanfile.
require CPANPLUS;

# Test::Pod::LinkCheck checks for link targets in @INC. We have to add these
# directories to be able to find link targets in this project.
use lib qw(bin lib blib);

use Test::Pod;
use Test::Pod::LinkCheck;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

Test::Pod::LinkCheck->new->all_pod_ok( Test::Pod::all_pod_files( grep { -d } qw(bin lib t xt) ) );
XT_AUTHOR_POD_LINKCHECK_T

=head2 xt/author/pod-links.t

L<Test::Pod::Links|Test::Pod::Links> author test.

=cut

    $file{q{xt/author/pod-links.t}} = $test_header . <<'XT_AUTHOR_POD_LINKS_T';
use Test::Pod::Links;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

Test::Pod::Links->new->all_pod_files_ok( grep { -d } qw(bin lib t xt) );
XT_AUTHOR_POD_LINKS_T

=head2 xt/author/pod-spell.t

L<Test::Spelling|Test::Spelling> author test. B<stopwords> are added as stopwords.

=cut

    $file{q{xt/author/pod-spell.t}} = sub {
        my ($self) = @_;

        my $content = $test_header . <<'XT_AUTHOR_POD_SPELL_T';
use Test::Spelling 0.12;
use Pod::Wordlist;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

add_stopwords(<DATA>);

all_pod_files_spelling_ok( grep { -d } qw( bin lib t xt ) );
__DATA__
XT_AUTHOR_POD_SPELL_T

        my @stopwords = grep { defined && !m{ ^ \s* $ }xsm } @{ $self->stopwords };
        push @stopwords, split /\s/xms, join q{ }, @{ $self->zilla->authors };

        $content .= join "\n", uniq( sort @stopwords ), q{};

        return $content;
    };

=head2 xt/author/pod-syntax.t

L<Test::Pod|Test::Pod> author test.

=cut

    $file{q{xt/author/pod-syntax.t}} = $test_header . <<'XT_AUTHOR_POD_SYNTAX_T';
use Test::Pod 1.26;

all_pod_files_ok( grep { -d } qw( bin lib t xt) );
XT_AUTHOR_POD_SYNTAX_T

=head2 xt/author/portability.t

L<Test::Portability::Files|Test::Portability::Files> author test.

=cut

    $file{q{xt/author/portability.t}} = $test_header . <<'XT_AUTHOR_PORTABILITY_T';
BEGIN {
    if ( !-f 'MANIFEST' ) {
        print "1..0 # SKIP No MANIFEST file\n";
        exit 0;
    }
}

use Test::Portability::Files;

options( test_one_dot => 0 );
run_tests();
XT_AUTHOR_PORTABILITY_T

=head2 xt/author/test-version.t

L<Test::Version|Test::Version> author test.

=cut

    $file{q{xt/author/test-version.t}} = $test_header . <<'XT_AUTHOR_TEST_VERSION_T';
use Test::More 0.88;
use Test::Version 0.04 qw( version_all_ok ), {
    consistent  => 1,
    has_version => 1,
    is_strict   => 0,
    multiple    => 0,
};

version_all_ok;
done_testing();
XT_AUTHOR_TEST_VERSION_T

=head2 xt/release/changes.t

L<Test::CPAN::Changes|Test::CPAN::Changes> release test.

=cut

    $file{q{xt/release/changes.t}} = $test_header . <<'XT_RELEASE_CHANGES_T';
use Test::CPAN::Changes;

changes_ok();
XT_RELEASE_CHANGES_T

=head2 xt/release/distmeta.t

L<Test::CPAN::Meta|Test::CPAN::Meta> release test.

=cut

    $file{q{xt/release/distmeta.t}} = $test_header . <<'XT_RELEASE_DISTMETA_T';
use Test::CPAN::Meta;

meta_yaml_ok();
XT_RELEASE_DISTMETA_T

=head2 xt/release/eol.t

L<Test::EOL|Test::EOL> release test.

=cut

    $file{q{xt/release/eol.t}} = $test_header . <<'XT_RELEASE_EOL_T';
use Test::EOL;

all_perl_files_ok( { trailing_whitespace => 1 }, grep { -d } qw( bin lib t xt) );
XT_RELEASE_EOL_T

=head2 xt/release/kwalitee.t

L<Test::Kwalitee|Test::Kwalitee> release test.

=cut

    $file{q{xt/release/kwalitee.t}} = sub {
        my ($self) = @_;

        my $kwalitee = $test_header . <<'XT_RELEASE_KWALITEE_T';
use Test::More 0.88;
use Test::Kwalitee 'kwalitee_ok';

# Module::CPANTS::Analyse does not find the LICENSE in scripts that don't end in .pl
XT_RELEASE_KWALITEE_T

        $kwalitee .= 'kwalitee_ok(';
        my @disabled = @{ $self->kwalitee_disable_test };
        if (@disabled) {
            $kwalitee .= 'qw{';
            $kwalitee .= join q{ }, map { "-$_" } @disabled;
            $kwalitee .= '}';
        }
        $kwalitee .= ");\n";

        $kwalitee .= <<'XT_RELEASE_KWALITEE_T';

done_testing();
XT_RELEASE_KWALITEE_T

        return $kwalitee;
    };

=head2 xt/release/manifest.t

L<Test::DistManifest|Test::DistManifest> release test.

=cut

    $file{q{xt/release/manifest.t}} = $test_header . <<'XT_RELEASE_MANIFEST_T';
use Test::DistManifest 1.003;

manifest_ok();
XT_RELEASE_MANIFEST_T

=head2 xt/release/meta-json.t

L<Test::CPAN::Meta::JSON|Test::CPAN::Meta::JSON> release test.

=cut

    $file{q{xt/release/meta-json.t}} = $test_header . <<'XT_RELEASE_META_JSON_T';
use Test::CPAN::Meta::JSON;

meta_json_ok();
XT_RELEASE_META_JSON_T

=head2 xt/release/meta-yaml.t

L<Test::CPAN::Meta|Test::CPAN::Meta> release test.

=cut

    $file{q{xt/release/meta-yaml.t}} = $test_header . <<'XT_RELEASE_META_YAML_T';
use Test::CPAN::Meta 0.12;

meta_yaml_ok();
XT_RELEASE_META_YAML_T
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=head1 USAGE

The following configuration options are supported:

=over 4

=item *

C<appveyor_test_on_cygwin> - Test with Cygwin on AppVeyor. Default to true.

=item *

C<appveyor_test_on_cygwin64> - Test with Cygwin64 on AppVeyor. Defaults to
true.

=item *

C<appveyor_test_on_strawberry> - Test with Strawberry Perl on AppVeyor.
Defaults to true.

=item *

C<ci_dist_zilla> - Generate the F<.travis.yml> and F<.appveyor.yml> which
installs the latest L<Dist::Zilla|Dist::Zilla> that runs on this version of
Perl. This is used to support tests that run with L<Test::DZil|Test::DZil>.

=item *

C<ci_earliest_perl> - Do not test on Perl versions older then this on
Travis CI and AppVeyor. Defaults to C<5.8>.

=item *

C<skip> - Defines files to be skipped (not generated).

=item *

C<stopwords> - Defines stopwords for the spell checker.

=item *

C<travis_ci_author_testing_perl> - Only run author tests on these versions.

=item *

C<travis_ci_osx_perl> - Only run this version on osx.

=back

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/dzil-inc/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/dzil-inc>

  git clone https://github.com/skirmess/dzil-inc.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
