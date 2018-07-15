package Dist::Zilla::PluginBundle::Author::SKIRMESS;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.000';

use Moose 0.99;

use Dist::Zilla::File::OnDisk;
use Dist::Zilla::Plugin::Author::SKIRMESS::ProjectSkeleton;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

use Carp;
use CHI;
use File::HomeDir;
use File::Spec;
use File::Temp ();
use HTTP::Tiny::Mech;
use Module::Metadata ();
use Path::Tiny;
use Perl::Critic::MergeProfile;
use WWW::Mechanize::Cached;

use namespace::autoclean 0.09;

has set_script_shebang => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{set_script_shebang} ? $_[0]->payload->{set_script_shebang} : 1;
    },
);

sub _find_files_extra_tests_files {
    my ($self) = @_;

    return if !-d 'xt';

    my $it = path('xt')->iterator( { recurse => 1 } );

    my @files;
  FILE:
    while ( defined( my $file = $it->() ) ) {
        next FILE if !-f $file;
        next FILE if $file !~ m{ [.] t $ }xsm;

        push @files, Dist::Zilla::File::OnDisk->new( { name => $file->absolute->stringify } );
    }

    return \@files;
}

sub configure {
    my ($self) = @_;

    # The Author::SKIRMESS plugin bundle is used to build other distributions
    # with Dist::Zilla, but it is also used to build the dzil-inc repository
    # itself. When the dzil-inc repository is built no distribution is
    # created as this repository is only intended to be included as
    # Git submodule by other distributions repositories.
    #
    # The $self_build variable is used to disable some Dist:Zilla plugins
    # that are only used in other distribution.
    #
    # If __FILE__ is inside lib/Dist/Zilla/PluginBundle/Author of the cwd we
    # are run with Bootstrap::lib in the dzil-inc repository which means we
    # are building the bundle. Otherwise we use the bundle to build another
    # distribution.
    my $self_build = -d 'lib/Dist/Zilla/PluginBundle/Author' && path('lib/Dist/Zilla/PluginBundle/Author')->realpath eq path(__FILE__)->parent()->realpath();

    my @template_files = qw(
      .perltidyrc
      xt/author/clean-namespaces.t
      xt/author/comment-spell.t
      xt/author/dependency-version.t
      xt/author/json-tidy.t
      xt/author/minimum-version.t
      xt/author/mojibake.t
      xt/author/no-tabs.t
      xt/author/perlcritic-code.t
      xt/author/perlcritic-tests.t
      xt/author/perltidy.t
      xt/author/pod-linkcheck.t
      xt/author/pod-links.t
      xt/author/pod-spell.t
      xt/author/pod-syntax.t
      xt/author/portability.t
      xt/author/test-version.t
      xt/release/changes.t
      xt/release/distmeta.t
      xt/release/eol.t
      xt/release/kwalitee.t
      xt/release/manifest.t
      xt/release/meta-json.t
      xt/release/meta-yaml.t
    );

    my @generated_files = Dist::Zilla::Plugin::Author::SKIRMESS::ProjectSkeleton->files();
    push @generated_files, qw(
      cpanfile
      LICENSE
      README.md
      t/00-load.t
    );

    if ( !$self_build ) {
        push @generated_files, qw(
          CONTRIBUTING
          INSTALL
          Makefile.PL
          META.json
          META.yml
          README
        );

        push @generated_files, @template_files;
    }

    my $dist_dir = __PACKAGE__;
    $dist_dir =~ s{::}{-}xsmg;

    my $ua = HTTP::Tiny::Mech->new(
        mechua => WWW::Mechanize::Cached->new(
            cache => CHI->new(
                driver   => 'File',
                root_dir => File::Spec->catdir( File::HomeDir->my_dist_data( $dist_dir, { create => 1 } ), '.cache' ),
            ),
        ),
    );

    $self->add_plugins(

        # Check at build/release time if modules are out of date
        [
            'PromptIfStale',
            {
                phase             => 'release',
                check_authordeps  => 1,
                check_all_plugins => 1,
                check_all_prereqs => 1,
                skip              => [ sort keys %{ Module::Metadata->package_versions_from_directory( $self_build ? 'lib' : 'dzil-inc/lib' ) } ],
            },
        ],

        # Add contributor names from git to your distribution
        'Git::Contributors',

        # Gather all tracked files in a Git working directory
        [
            'Git::GatherDir',
            {
                ':version'       => '2.016',
                exclude_filename => [
                    qw(
                      COMPATIBILITY
                      dist.ini
                      xt/author/perlcriticrc-code
                      xt/author/perlcriticrc-tests
                      ),
                    @generated_files,

                    # template files are in #generated_files for non-self builds
                    ( $self_build ? @template_files : () ),
                ],
                exclude_match    => '^xt/(.+/)?.+[.]config$',
                include_dotfiles => 1,
            },
        ],

        # Set the distribution version from your main module's $VERSION
        ( $self_build ? () : 'VersionFromMainModule' ),

        # Bump and reversion $VERSION on release
        [
            'ReversionOnRelease',
            {
                prompt => 1,
            },
        ],

        # maintain a base set of files in the project
        [
            'Author::SKIRMESS::ProjectSkeleton',
            {
                (
                    $self_build
                    ? ( makefile_pl_exists => 0, )
                    : ( makefile_pl_exists => 1, ),
                    ua => [$ua],
                ),
            },
        ],

        # Add files to the project from templates
        (
            $self_build
            ? ()
            : [
                'Author::SKIRMESS::AddFilesToProject',
                {
                    file               => [@template_files],
                    root               => 'dzil-inc',
                    'config.generated' => 'Automatically generated file; DO NOT EDIT.',
                },
            ],
        ),

        # Check at build/release time if modules are out of date
        [
            'PromptIfStale', 'PromptIfStale / CPAN::Perl::Releases',
            {
                phase  => 'build',
                module => [qw(CPAN::Perl::Releases)],
            },
        ],

        # Create the t/00-load.t test
        'Author::SKIRMESS::Test::Load',

        # update Pod with project specific defaults
        'Author::SKIRMESS::UpdatePod',

        # fix the file permissions in your Git repository with Dist::Zilla
        'Git::FilePermissions',

        # Enforce the correct line endings in your Git repository with Dist::Zilla
        'Git::RequireUnixEOL',

        # Update the next release number in your changelog
        (
            $self_build
            ? ()
            : [
                'NextRelease',
                {
                    format    => '%v  %{yyyy-MM-dd HH:mm:ss VVV}d',
                    time_zone => 'UTC',
                },
            ]
        ),

        # Prune stuff that you probably don't mean to include
        'PruneCruft',

        # Decline to build files that appear in a MANIFEST.SKIP-like file
        'ManifestSkip',

        # :ExtraTestFiles is empty because we don't add xt test files to the
        # distribution, that's why we have to create a new ExtraTestFiles
        # plugin
        #
        # code must be a single value but inside an array ref. Bug is
        # reported as:
        # https://github.com/rjbs/Config-MVP/issues/13
        [
            'FinderCode', 'ExtraTestFiles',
            {
                code  => [ \&_find_files_extra_tests_files ],
                style => 'list',
            },
        ],

        # automatically extract prereqs from your modules
        [
            'AutoPrereqs',
            {
                develop_finder => [ ':ExtraTestFiles', '@Author::SKIRMESS/ExtraTestFiles', ],    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
            },
        ],

        # automatically extract Perl::Critic policy prereqs
        [
            'AutoPrereqs::Perl::Critic', 'AutoPrereqs::Perl::Critic / code',
            {
                critic_config => $self->_perlcriticrc('code'),
            },
        ],

        [
            'AutoPrereqs::Perl::Critic', 'AutoPrereqs::Perl::Critic / tests',
            {
                critic_config => $self->_perlcriticrc('tests'),
            },
        ],

        # Set script shebang to #!perl
        ( $self->set_script_shebang ? 'SetScriptShebang' : () ),

        # Detects the minimum version of Perl required for your dist
        [
            'MinimumPerl',
            {
                ':version' => '1.006',
            },
        ],

        # Stop CPAN from indexing stuff
        (
            $self_build
            ? ()
            : [
                'MetaNoIndex',
                {
                    directory => [ qw(t xt), grep { -d } qw(corpus demo examples fatlib inc local perl5 share) ],
                },
            ]
        ),

        # Automatically include GitHub meta information in META.yml
        [
            'GithubMeta',
            {
                issues => 1,
            },
        ],

        # Automatically convert POD to a README in any format for Dist::Zilla
        [
            'ReadmeAnyFromPod',
            {
                type     => 'markdown',
                filename => 'README.md',
                location => 'root',
            },
        ],

        # Extract namespaces/version from traditional packages for provides
        'MetaProvides::Package',

        # Extract namespaces/version from traditional packages for provides
        #
        # This adds packages found in scripts under bin which are skipped
        # by the default finder of MetaProvides::Package above.
        [
            'MetaProvides::Package', 'MetaProvides::Package/ExecFiles',
            {
                meta_noindex => 1,
                finder       => ':ExecFiles',
            },
        ],

        # delete the develop prereqs from the distmeta
        'Author::SKIRMESS::RemoveDevelopPrereqs',

        # Produce a META.yml
        ( $self_build ? () : 'MetaYAML' ),

        # Produce a META.json
        ( $self_build ? () : 'MetaJSON' ),

        # Produce a cpanfile prereqs file
        [
            'Author::SKIRMESS::CPANFile',
            {
                develop_prereqs => '@Author::SKIRMESS/Author::SKIRMESS::RemoveDevelopPrereqs',    ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
            },
        ],

        # check that the copyright year is correct
        'Author::SKIRMESS::CheckCopyrightYear',

        # check that the distribution contains only the correct files
        [
            'Author::SKIRMESS::CheckFilesInDistribution',
            {
                required_file => [
                    qw(LICENSE Makefile.PL MANIFEST README),
                    ( $self_build ? () : qw(Changes CONTRIBUTING INSTALL META.json META.yml) ),
                ],
            },
        ],

        # Automatically convert POD to a README in any format for Dist::Zilla
        [ 'ReadmeAnyFromPod', 'ReadmeAnyFromPod/ReadmeTextInBuild' ],

        # remove whitespace at end of line
        (
            $self_build
            ? ()
            : [
                'Author::SKIRMESS::RemoveWhitespaceFromEndOfLine',
                {
                    file => [qw(README)],
                },
            ]
        ),

        # Output a LICENSE file
        'License',

        # Build an INSTALL file
        (
            $self_build
            ? ()
            : [
                'InstallGuide',
                {
                    ':version' => '1.200007',
                },
            ]
        ),

        # build an CONTRIBUTING file
        ( $self_build ? () : 'Author::SKIRMESS::ContributingGuide' ),

        # Install a directory's contents as executables
        'ExecDir',

        # Install a directory's contents as "ShareDir" content
        'ShareDir',

        # Build a Makefile.PL that uses ExtUtils::MakeMaker
        'MakeMaker',

        # list simple prerequisites
        [
            'Prereqs::Floor',
            {
                # http://blogs.perl.org/users/ovid/2014/02/moose-dying-with-invalid-version-format-version-required.html#comments
                # Moose 2.1202 or below fails with newer versions of Module::Runtime
                'Moose' => '2.1203',

                # https://github.com/dagolden/Test-TempDir-Tiny/pull/14
                'Test::TempDir::Tiny' => '0.017',
            },
        ],

        # Support running xt tests via dzil test from the project
        [
            'Author::SKIRMESS::RunExtraTests::FromProject',
            {
                skip_project => [
                    qw(
                      xt/author/clean-namespaces.t
                      xt/author/minimum_version.t
                      xt/author/perlcritic-code.t
                      xt/author/pod-no404s.t
                      xt/author/pod-spell.t
                      xt/author/pod-syntax.t
                      xt/author/portability.t
                      xt/author/test-version.t
                      xt/release/changes.t
                      xt/release/distmeta.t
                      xt/release/kwalitee.t
                      xt/release/manifest.t
                      xt/release/meta-json.t
                      xt/release/meta-yaml.t
                      ),
                ],
            },
        ],

        # Build a MANIFEST file
        'Manifest',

        # Check that you're on the correct branch before release
        'Git::CheckFor::CorrectBranch',

        # Check your repo for merge-conflicted files
        'Git::CheckFor::MergeConflicts',

        # Ensure META includes resources
        'CheckMetaResources',

        # Prevent a release if you have prereqs not found on CPAN
        'CheckPrereqsIndexed',

        # Ensure Changes has content before releasing
        'CheckChangesHasContent',

        # Check if your distribution declares a dependency on itself
        'CheckSelfDependency',

        # BeforeRelease plugin to check for a strict version number
        [
            'CheckStrictVersion',
            {
                decimal_only => 1,
            },
        ],

        # Extract archive and run tests before releasing the dist
        'TestRelease',

        # Retrieve count of outstanding RT and github issues for your distribution
        'CheckIssues',

        # Prompt for confirmation before releasing
        'ConfirmRelease',

        # Upload the dist to CPAN
        'UploadToCPAN',

        # copy all files from the distribution to the project (after build and release)
        [
            'Author::SKIRMESS::CopyAllFilesFromDistributionToProject',
            {
                skip_file => [
                    qw(MANIFEST),
                    ( $self_build ? qw(Makefile.PL README) : qw(Changes) ),
                ],
            },
        ],

        # Commit dirty files
        [
            'Git::Commit',
            {
                commit_msg  => '%v',
                allow_dirty => [
                    qw(
                      Changes
                      ),
                    @generated_files,
                ],
                allow_dirty_match => [qw( \.pm$ \.pod$ ^bin/ )],
            },
        ],

        # Tag the new version
        [
            'Git::Tag',
            {
                tag_format  => '%v',
                tag_message => q{},
            },
        ],

        # Push current branch
        'Git::Push',

        # Compare data and files at different phases of the distribution build process
        # listed last, to be sure we run at the very end of each phase
        'VerifyPhases',
    );

    return;
}

# Files created by File::Temp->new are removed as soon as the object is
# destroyed. This is here to keep them around until the program ends.
my @TEMP_FILES;

sub _tempfile {
    my ($self) = @_;

    push @TEMP_FILES, File::Temp->new;
    return $TEMP_FILES[-1]->filename;
}

sub _perlcriticrc {
    my ( $self, $code_or_tests ) = @_;

    return 'xt/author/perlcriticrc' if !-f "xt/author/perlcriticrc-$code_or_tests";

    my $merge = Perl::Critic::MergeProfile->new;
    $merge->read('xt/author/perlcriticrc');
    $merge->read("xt/author/perlcriticrc-$code_or_tests");

    my $rc_file = $self->_tempfile;
    $merge->write($rc_file) or croak "Cannot write merged Perl::Critic profile to $rc_file: $!";

    return $rc_file;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::PluginBundle::Author::SKIRMESS - Dist::Zilla configuration the way SKIRMESS does it

=head1 VERSION

Version 1.000

=head1 SYNOPSIS

=head2 Create a new dzil project

Create a new repository on Github and clone it.

  $ git submodule add ../dzil-inc.git
  $ git commit -m 'added Author::SKIRMESS plugin bundle as git submodule'

  # in dist.ini
  [lib]
  lib = dzil-inc/lib

  [@Author::SKIRMESS]

=head2 Clone a project which already contains this submodule

  $ git clone https://github.com/skirmess/...
  $ git submodule update --init

  # To update dzil-inc
  $ cd dzil-inc && git checkout master


=head2 Update the submodule

  $ cd dzil-inv && git pull

=head1 DESCRIPTION

This is a L<Dist::Zilla|Dist::Zilla> PluginBundle.

The bundle will not be released on CPAN, instead it is designed to be
included as Git submodule in the project that will use it.

=head1 USAGE

To use this PluginBundle, include it as Git submodule in your project and
add it to your dist.ini. You can provide the following options:

=over 4

=item *

C<set_script_shebang> - this indicates whether C<SetScriptShebang> should be used or not

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
