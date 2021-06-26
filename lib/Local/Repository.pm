package Local::Repository;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

with 'Local::Role::Template';

use Carp;
use CPAN::Perl::Releases qw(perl_versions);
use File::pushd;
use Git::Wrapper;
use Path::Tiny qw(path);
use version 0.77 ();

use Local::Workflow;

use namespace::autoclean 0.09;

has github_actions_min_perl => (
    is      => 'ro',
    default => '5.8.1',
);

has github_actions_min_perl_linux => (
    is      => 'ro',
    default => sub { $_[0]->github_actions_min_perl },
);

has github_actions_min_perl_windows => (
    is      => 'ro',
    default => sub { $_[0]->github_actions_min_perl },
);

has github_actions_min_perl_strawberry => (
    is      => 'ro',
    default => sub { $_[0]->github_actions_min_perl },
);

has makefile_pl_exists => (
    is      => 'ro',
    default => 1,
);

has push_url => (
    is => 'ro',
);

has repo => (
    is       => 'ro',
    required => 1,
);

has skip => (
    is      => 'ro',
    default => sub { [] },
);

# -----

has repo_dir => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { path( $_[0]->repo )->basename('.git') },
    init_arg => undef,
);

sub _clone_or_update_project {
    my ($self) = @_;

    if ( !-d 'repos' ) {
        path('repos')->mkpath;
    }

    my $repo_dir_abs = path('repos')->absolute->child( $self->repo_dir );
    my $git          = Git::Wrapper->new($repo_dir_abs);

    if ( -d $repo_dir_abs ) {
        if ( $git->status->is_dirty ) {
            say ' ==> Repository is dirty, skipping update';
            return;
        }

        say ' ==> pulling repo';
        $git->pull;
    }
    else {
        say ' ==> cloning repo';
        $git->clone( $self->repo, $repo_dir_abs );
    }

    my $push_url = $self->push_url;
    if ( defined $push_url ) {
        $git->remote( 'set-url', '--push', 'origin', $push_url );
    }

    return;
}

sub _copy_files_from_submodule_to_project {
    my ($self) = @_;

    say ' ==> Copy files to project';

    my $it = path('templates')->iterator( { recurse => 1 } );

    my %skip = map { $_ => 1 } @{ $self->skip };
  FILE:
    while ( defined( my $file_abs = $it->() ) ) {
        next FILE if -l $file_abs || !-f _;

        my $file = $file_abs->relative( path('templates') );
        confess "File '$file' is not relative" if !$file->is_relative;

        if ( exists $skip{$file} ) {

            # say "Skipping file $file";
            next FILE;
        }

        my $content = $self->fill_in_file( $file_abs->stringify );

        confess "Filling in the template returned undef for file '$file': $Text::Template::ERROR" if !defined $content;

        my $target        = path('repos')->child( $self->repo_dir )->child($file);
        my $target_parent = $target->parent;

        if ( !-d $target_parent ) {
            confess "'$target_parent' exists but is not a directory" if -e $target_parent;

            say "Creating dir '$target_parent'";
            $target_parent->mkpath;
        }

        # say "Creating file '$target' from template '" . $file_abs . q{'};

        $target->spew($content);
    }

    return;
}

sub _create_github_actions {
    my ($self) = @_;

    for my $x (
        qw(
        github_actions_min_perl_linux
        github_actions_min_perl_windows
        github_actions_min_perl_strawberry
        )
      )
    {
        my $version = $self->$x;
        die "Version must be major.minor.patch but is $version" if $version !~ m{ ^ [1-9][0-9]* [.] [0-9]+ [.] [0-9]+ $ }xsm;
    }

    my $actions = Local::Workflow->new(
        min_perl_linux      => $self->github_actions_min_perl_linux,
        min_perl_windows    => $self->github_actions_min_perl_windows,
        min_perl_strawberry => $self->github_actions_min_perl_strawberry,
    )->create;

    my $actions_path = path('repos')->child( $self->repo_dir )->child('.github/workflows');
    $actions_path->mkpath;

    say " ==> Creating Github Actions Workflow";
    $actions_path->child('test.yml')->spew($actions);

    return;
}

sub _remove_files {
    my ($self) = @_;

    my $wd = pushd( path('repos')->child( $self->repo_dir )->stringify );

  FILE:
    for my $file ( qw(.appveyor.yml .travis.yml), glob q{xt/*/*.t} ) {
        next FILE if !-f $file;

        unlink $file;
    }

    return;
}

sub update_project {
    my ($self) = @_;

    say '===> ', $self->repo;

    $self->_clone_or_update_project;
    $self->_remove_files;
    $self->_create_github_actions;
    $self->_copy_files_from_submodule_to_project;

    return;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
