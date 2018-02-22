package MyBundle;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.033';

# This is needed to load patched modules from Dist-Zilla-Config-Slicer
use lib::relative '../inc/lib';

use Moose 0.99;

use MyRepositoryBase;

with qw(
  Dist::Zilla::Role::PluginBundle::Easy
  Dist::Zilla::Role::PluginBundle::Config::Slicer
);

has set_script_shebang => (
    is      => 'ro',
    isa     => 'Bool',
    lazy    => 1,
    default => sub {
        exists $_[0]->payload->{set_script_shebang} ? $_[0]->payload->{set_script_shebang} : 1;
    },
);

use Path::Tiny;

use namespace::autoclean 0.09;

sub configure {
    my ($self) = @_;

    # The MyBundle plugin bundle is used to build other distributions with
    # Dist::Zilla, but it is also used to build the dzil-inc repository
    # itself. When the dzil-inc repository is built no distribution is
    # created as this repository is only intended to be included as
    # Git submodule by other distributions repositories.
    #
    # The $self_build variable is used to disable some Dist:Zilla plugins
    # that are only used in other distribution.
    #
    # If __FILE__ is inside lib of the cwd we are run with Bootstrap::lib
    # in the dzil-inc repository which means we are building the bundle.
    # Otherwise we use the bundle to build another distribution.
    my $self_build = path('lib')->realpath eq path(__FILE__)->realpath()->parent();

    my @generated_files = MyRepositoryBase->files();

    $self->add_plugins(

        # Check at build/release time if modules are out of date
        [
            'PromptIfStale',
            {
                phase             => 'release',
                check_authordeps  => 1,
                check_all_plugins => 1,
                check_all_prereqs => 1,
            },
        ],

        # Add contributor names from git to your distribution
        'Git::Contributors',

        # Gather all tracked files in a Git working directory
        [
            'Git::GatherDir',
            {
                ':version'       => '2.016',
                exclude_filename => [qw( cpanfile dist.ini INSTALL LICENSE Makefile.PL META.json META.yml README README.md )],
                include_dotfiles => 1,
            },
        ],

        # Set the distribution version from your main module's $VERSION
        'VersionFromMainModule',

        # Bump and reversion $VERSION on release
        [
            'ReversionOnRelease',
            {
                prompt => 1,
            },
        ],

        # Must run after ReversionOnRelease because it adds the version of
        # the bundle to the generated files
        [
            '=MyRepositoryBase',
            {
                (
                    $self_build
                    ? (
                        makefile_pl_exists => 0,
                        skip               => [
                            qw(
                              xt/release/changes.t
                              xt/release/distmeta.t
                              xt/release/kwalitee.t
                              xt/release/manifest.t
                              xt/release/meta-json.t
                              xt/release/meta-yaml.t
                              ),
                        ],
                      )
                    : ( makefile_pl_exists => 1, )
                ),
            },
        ],

        '=MyInsertVersion',

        'Git::FilePermissions',

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

        # Check your git repository before releasing
        [
            'Git::Check',
            {
                allow_dirty => [ qw( Changes cpanfile dist.ini Makefile.PL META.json META.yml README README.md ), @generated_files ],
            },
        ],

        # Prune stuff that you probably don't mean to include
        'PruneCruft',

        # Decline to build files that appear in a MANIFEST.SKIP-like file
        'ManifestSkip',

        # automatically extract prereqs from your modules
        [
            'AutoPrereqs',
            {
                skip => [qw( ^t::lib )],
            },
        ],

        # automatically extract Perl::Critic policy prereqs
        [
            'AutoPrereqs::Perl::Critic', 'AutoPrereqs::Perl::Critic / code',
            {
                critic_config => 'xt/author/perlcriticrc-code',
            },
        ],

        [
            'AutoPrereqs::Perl::Critic', 'AutoPrereqs::Perl::Critic / tests',
            {
                critic_config => 'xt/author/perlcriticrc-tests',
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
                    directory => [ qw(t xt), grep { -d } qw(corpus demo examples fatlib inc local perl5 share ) ],
                },
            ]
        ),

        # Automatically include GitHub meta information in META.yml
        (
            $self_build
            ? ()
            : [
                'GithubMeta',
                {
                    issues => 1,
                },
            ]
        ),

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

        # Produce a META.yml
        ( $self_build ? () : 'MetaYAML' ),

        # Produce a META.json
        ( $self_build ? () : 'MetaJSON' ),

        # Produce a cpanfile prereqs file
        '=MyCPANFile',

        # Automatically convert POD to a README in any format for Dist::Zilla
        [ 'ReadmeAnyFromPod', 'ReadmeAnyFromPod/ReadmeTextInBuild' ],

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

        # Install a directory's contents as executables
        'ExecDir',

        # Install a directory's contents as "ShareDir" content
        'ShareDir',

        # Build a Makefile.PL that uses ExtUtils::MakeMaker
        ( $self_build ? () : 'MakeMaker' ),

        # Build a MANIFEST file
        'Manifest',

        # Copy (or move) specific files after building (for SCM inclusion, etc.)
        [
            'CopyFilesFromBuild',
            {
                copy => [
                    qw(LICENSE),
                    ( $self_build ? () : qw(INSTALL Makefile.PL META.json META.yml README) ),
                ],
            },
        ],

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

        # Support running xt tests via dzil test
        'RunExtraTests',

        # Extract archive and run tests before releasing the dist
        'TestRelease',

        # Retrieve count of outstanding RT and github issues for your distribution
        'CheckIssues',

        # Prompt for confirmation before releasing
        'ConfirmRelease',

        # Upload the dist to CPAN
        'UploadToCPAN',

        # Copy files from a release (for SCM inclusion, etc.)
        [
            'CopyFilesFromRelease',
            {
                match => [qw( \.pm$ ^bin/ )],
            },
        ],

        # Commit dirty files
        [
            'Git::Commit',
            {
                commit_msg        => '%v',
                allow_dirty       => [ qw(Changes cpanfile dist.ini INSTALL LICENSE Makefile.PL META.json META.yml README.md), @generated_files ],
                allow_dirty_match => [qw( \.pm$ ^bin/ )],
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

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MyBundle - Dist::Zilla configuration the way SKIRMESS does it

=head1 VERSION

Version 0.033

=head1 SYNOPSIS

  # in dist.ini
  [@Author::SKIRMESS]

=head1 DESCRIPTION

This is a L<Dist::Zilla|Dist::Zilla> PluginBundle.

=head1 USAGE

To use this PluginBundle, just add it to your dist.ini. You can provide the
following options:

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

=head1 SEE ALSO

L<Dist::Zilla::PluginBundle::Author::ETHER|Dist::Zilla::PluginBundle::Author::ETHER>,
L<Dist::Zilla::PluginBundle::DAGOLDEN|Dist::Zilla::PluginBundle::DAGOLDEN>,
L<Dist::Zilla::PluginBundle::Milla|Dist::Zilla::PluginBundle::Milla>,
L<Dist::Milla|Dist::Milla>

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
