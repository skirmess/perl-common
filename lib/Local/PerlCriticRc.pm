package Local::PerlCriticRc;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

with 'Local::Role::Template';

use Carp;
use CPAN::Meta::YAML ();
use HTTP::Tiny       ();
use Path::Tiny       qw(path);
use Text::Trim;

use namespace::autoclean 0.09;

sub create {
    my ( $self, $file ) = @_;

    say " ==> Creating file $file (perlcritic config file)";

    my $content = <<'PERLCRITICRC_TEMPLATE';
# {{ $generated }}

only = 1
profile-strictness = fatal
severity = 1
verbose = [%p] %m at %f line %l, near '%r'\n
PERLCRITICRC_TEMPLATE

    my $it = $self->_perl_critic_config_block;
    while ( defined( my $line = $it->() ) ) {
        $content .= $line;
    }

    path($file)->spew( $self->fill_in_string($content) );

    return;
}

# Returns an iterator that iterates over all policies of all the perlcritic
# policy distributions we use. Return value is a string containing the
# configuration of one policy, or a comment block.
#
# The returned string are expected to be concatenated together to create
# the perlcriticrc config file.
sub _perl_critic_config_block {
    my ($self) = @_;

    my $it = $self->_perl_critic_policy_default_config;

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

# Returns an iterator that iterates over all policies of all the perlcritic
# policy distributions we use. Return value is an array ref of the
# distribution name and the policy name.
sub _perl_critic_policy {
    my ($self) = @_;

    my $dist_it = $self->_perl_critic_policy_distributions;
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
# distribution name, the policy name, if the policy should be enabled and
# either undef or a hash ref of default configuration for that policy.
#
# This method contains a list a default configurations we like.
sub _perl_critic_policy_default_config {
    my ($self) = @_;

    my $it = $self->_perl_critic_policy_default_enabled;

    return sub {
        my $pol_ref = $it->();
        return if !defined $pol_ref;

        my $policy = $pol_ref->[1];

        push @{$pol_ref},

          # Core Policies
            $policy eq 'ErrorHandling::RequireCarping'                 ? { allow_in_main_unless_in_subroutine => '1' }
          : $policy eq 'InputOutput::RequireCheckedSyscalls'           ? { functions                          => ':builtins', exclude_functions => 'exec print say sleep' }
          : $policy eq 'Modules::ProhibitEvilModules'                  ? { modules                            => $self->_prohibit_evil_modules() }
          : $policy eq 'Subroutines::ProhibitUnusedPrivateSubroutines' ? { private_name_regex                 => '_(?!build_)\w+' }
          : $policy eq 'ValuesAndExpressions::ProhibitComplexVersion'  ? { forbid_use_version                 => '1' }

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
        'Modules::ProhibitMultiplePackages',
        'Modules::RequireExplicitPackage',
        'Modules::RequireVersionVar',
        'NamingConventions::Capitalization',
        'RegularExpressions::ProhibitComplexRegexes',
        'RegularExpressions::ProhibitEnumeratedClasses',
        'Subroutines::ProhibitExcessComplexity',
        'Subroutines::ProhibitSubroutinePrototypes',
        'Subroutines::RequireArgUnpacking',
        'ValuesAndExpressions::ProhibitConstantPragma',
        'ValuesAndExpressions::ProhibitLeadingZeros',
        'ValuesAndExpressions::ProhibitLongChainsOfMethodCalls',
        'ValuesAndExpressions::ProhibitMagicNumbers',
        'Variables::ProhibitPunctuationVars',

        # Perl::Critic::Bangs
        'Bangs::ProhibitCommentedOutCode',
        'Bangs::ProhibitNoPlan',
        'Bangs::ProhibitNumberedNames',
        'Bangs::ProhibitVagueNames',

        # Perl::Critic::Community
        'Community::EmptyReturn',

        # Perl::Critic::Itch
        'CodeLayout::ProhibitHashBarewords',

        # Perl::Critic::Lax
        'Lax::ProhibitEmptyQuotes::ExceptAsFallback',
        'Lax::ProhibitLeadingZeros::ExceptChmod',
        'Lax::ProhibitStringyEval::ExceptForRequire',
        'Lax::RequireConstantOnLeftSideOfEquality::ExceptEq',
        'Lax::RequireEndWithTrueConst',

        # Perl::Critic::More
        'CodeLayout::RequireASCII',
        'Editor::RequireEmacsFileVariables',
        'ErrorHandling::RequireUseOfExceptions',
        'ValuesAndExpressions::RequireConstantOnLeftSideOfEquality',
        'ValuesAndExpressions::RestrictLongStrings',

        # Perl::Critic::Pulp
        'CodeLayout::ProhibitIfIfSameLine',
        'Compatibility::Gtk2Constants',

        # Disable the Compatibility::PerlMinimumVersionAndWhy policy because
        # it injects stuff into the Perl::MinimumVersion module that causes
        # hard to debug problems.
        'Compatibility::PerlMinimumVersionAndWhy',
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

    my $it = $self->_perl_critic_policy;

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

                confess "Policy '$policy' is disabled but does not exist.";
            }

            return;
        }

        push @{$pol_ref}, exists $disabled_policies{ $pol_ref->[1] } ? 0 : 1;
        $disabled_policies{ $pol_ref->[1] } = 1;

        return $pol_ref;
    };
}

# Returns an iterator that iterates over the perlcritic policy distributions
# we use.
sub _perl_critic_policy_distributions {
    my ($self) = @_;

    my @stack = qw(
      Perl::Critic
      Perl::Critic::Bangs
      Perl::Critic::Community
      Perl::Critic::Itch
      Perl::Critic::Lax
      Perl::Critic::Moose
      Perl::Critic::More
      Perl::Critic::PetPeeves::JTRAMMELL
      Perl::Critic::Policy::BuiltinFunctions::ProhibitDeleteOnArrays
      Perl::Critic::Policy::BuiltinFunctions::ProhibitReturnOr
      Perl::Critic::Policy::HTTPCookies
      Perl::Critic::Policy::Moo::ProhibitMakeImmutable
      Perl::Critic::Policy::TryTiny::RequireBlockTermination
      Perl::Critic::Policy::TryTiny::RequireUse
      Perl::Critic::Policy::ValuesAndExpressions::PreventSQLInjection
      Perl::Critic::Policy::ValuesAndExpressions::ProhibitSingleArgArraySlice
      Perl::Critic::Policy::Variables::ProhibitLoopOnHash
      Perl::Critic::Policy::Variables::ProhibitUnusedVarsStricter
      Perl::Critic::Pulp
      Perl::Critic::StricterSubs
      Perl::Critic::Tics
    );

    return sub {
        return if !@stack;
        return shift @stack;
    };
}

# Returns an iterator that can be used to iterate over all the perlcritic
# policies in a policy distribution.
sub _perl_critic_policy_from_distribution {
    my ( $self, $distribution ) = @_;

    my $url = "http://cpanmetadb.plackperl.org/v1.0/package/$distribution";
    say "Downloading '$url'...";
    my $res = HTTP::Tiny->new->get($url);

    confess "Cannot download '$url': $res->{reason}" if !$res->{success};

    my $yaml = CPAN::Meta::YAML->read_string( $res->{content} ) or confess CPAN::Meta::YAML->errstr;
    my $meta = $yaml->[0];

    confess 'Unable to parse returned data' if !exists $meta->{provides};

    my @policies;
  MODULE:
    for my $module ( keys %{ $meta->{provides} } ) {
        if ( $module =~ m{ ^ Perl::Critic::Policy:: ( .+ ) }xsm ) {
            push @policies, $1;
        }
    }

    # The Perl::Critic::Freenode dist was renamed to Community and all
    # policies added twice with an alias. Remove the duplicate policies
    if ( $distribution eq 'Perl::Critic::Community' ) {
        my %policy = map { $_ => 1 } @policies;
        for my $policy ( grep { m{ ^ Community:: }xsm } @policies ) {
            $policy =~ s{ ^ Community:: }{Freenode::}xsm;
            delete $policy{$policy};
        }

        @policies = keys %policy;
    }

    my @stack = sort { lc $a cmp lc $b } @policies;

    return sub {
        return if !@stack;
        return shift @stack;
    };
}

sub _prohibit_evil_modules {
    my ($self) = @_;

    my @evil_modules = (
        [ 'Class::ISA'        => 'Found use of Class::ISA. This module is deprecated by the Perl 5 Porters.' ],
        [ 'Pod::Plainer'      => 'Found use of Pod::Plainer. This module is deprecated by the Perl 5 Porters.' ],
        [ 'Shell'             => 'Found use of Shell. This module is deprecated by the Perl 5 Porters.' ],
        [ 'Switch'            => 'Found use of Switch. This module is deprecated by the Perl 5 Porters.' ],
        [ 'Readonly'          => 'Found use of Readonly. Please use constant.pm or Const::Fast.' ],
        [ 'base'              => 'Found use of base. Please use parent instead.' ],
        [ 'File::Slurp'       => 'Found use of File::Slurp. Please use Path::Tiny instead.' ],
        [ 'common::sense'     => 'Found use of common::sense. Please use strict and warnings instead.' ],
        [ 'Class::Load'       => 'Found use of Class::Load. Please use Module::Runtime instead.' ],
        [ 'Any::Moose'        => 'Found use of Any::Moose. Please use Moo instead.' ],
        [ 'Error'             => 'Found use of Error.pm. Please use Throwable.pm instead.' ],
        [ 'Getopt::Std'       => 'Found use of Getopt::Std. Please use Getopt::Long instead.' ],
        [ 'HTML::Template'    => 'Found use of HTML::Template. Please use Template::Toolkit.' ],
        [ 'IO::Socket::INET6' => 'Found use of IO::Socket::INET6. Please use IO::Socket::IP.' ],
        [ 'JSON'              => 'Found use of JSON. Please use JSON::PP, JSON::MaybeXS, or Cpanel::JSON::XS.' ],
        [ 'JSON::XS'          => 'Found use of JSON::XS. Please use JSON::PP, JSON::MaybeXS, or Cpanel::JSON::XS.' ],
        [ 'JSON::Any'         => 'Found use of JSON::Any. Please use JSON::PP, JSON::MaybeXS, or Cpanel::JSON::XS.' ],
        [ 'List::MoreUtils'   => 'Found use of List::MoreUtils. Please use List::Util or List::UtilsBy.' ],
        [ 'Mouse'             => 'Found use of Mouse. Please use Moo.' ],
        [ 'Net::IRC'          => 'Found use of Net::IRC. Please use POE::Component::IRC, Net::Async::IRC, or Mojo::IRC.' ],
        [ 'XML::Simple'       => 'Found use of XML::Simple. Please use XML::LibXML, XML::TreeBuilder, XML::Twig, or Mojo::DOM.' ],
        [ 'Sub::Infix'        => 'Found use of Sub::Infix. Please do not use it.' ],
        [ 'vars'              => 'the vers pragma has been superseded by our declarations, available in Perl v5.6.0 or later, and use of this pragma is discouraged.' ],
    );

    my $result = q{ };
    for my $evil_ref (@evil_modules) {
        $result .= "$evil_ref->[0] {$evil_ref->[1]} ";
    }

    trim $result;

    return $result;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
