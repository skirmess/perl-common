package Local::Repository;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

with 'Local::Role::Template';

use Carp;

#use Git::Wrapper;
use Path::Tiny qw(path);
use Perl::PrereqScanner;

use Local::Workflow;

use namespace::autoclean 0.09;

has common_dir => (
    is       => 'ro',
    required => 1,
);

has github_workflow => (
    is      => 'ro',
    default => 1,
);

has github_workflow_min_perl => (
    is      => 'ro',
    default => '5.8.1',
);

has github_workflow_min_perl_linux => (
    is      => 'ro',
    default => sub { $_[0]->github_workflow_min_perl },
);

has github_workflow_min_perl_strawberry => (
    is      => 'ro',
    default => sub { $_[0]->github_workflow_min_perl },
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

#sub _clone_or_update_project {
#    my ($self) = @_;

#    if ( !-d 'repos' ) {
#        path('repos')->mkpath;
#    }

#    my $repo_dir_abs = path('repos')->absolute->child( $self->repo_dir );
#    my $git          = Git::Wrapper->new($repo_dir_abs);

#    if ( -d $repo_dir_abs ) {
#        if ( $git->status->is_dirty ) {
#            say ' ==> Repository is dirty, skipping update';
#            return;
#        }

#        say ' ==> pulling repo';
#        $git->pull;
#    }
#    else {
#        say ' ==> cloning repo';
#        $git->clone( $self->repo, $repo_dir_abs );
#    }

#    my $push_url = $self->push_url;
#    if ( defined $push_url ) {
#        $git->remote( 'set-url', '--push', 'origin', $push_url );
#    }

#    return;
#}

sub _copy_files_from_submodule_to_project {
    my ($self) = @_;

    say ' ==> Copy files to project';

    my $it = path( $self->common_dir )->child('templates')->iterator( { recurse => 1 } );

    my %skip = map { $_ => 1 } @{ $self->skip };
  FILE:
    while ( defined( my $file_abs = $it->() ) ) {
        next FILE if -l $file_abs || !-f _;

        my $file = $file_abs->relative( path( $self->common_dir )->child('templates') );
        confess "File '$file' is not relative" if !$file->is_relative;

        if ( exists $skip{$file} ) {

            say "Skipping file $file";
            next FILE;
        }

        my $content = $self->fill_in_file( $file_abs->stringify );

        confess "Filling in the template returned undef for file '$file': $Text::Template::ERROR" if !defined $content;

        my $target_parent = $file->parent;

        if ( !-d $target_parent ) {
            confess "'$target_parent' exists but is not a directory" if -e $target_parent;

            say "Creating dir '$target_parent'";
            $target_parent->mkpath;
        }

        say "Creating file '$file' from template '" . $file_abs . q{'};

        $file->spew($content);
    }

    return;
}

sub _create_github_workflow {
    my ($self) = @_;

    for my $x (
        qw(
        github_workflow_min_perl_linux
        github_workflow_min_perl_strawberry
        )
      )
    {
        my $version = $self->$x;
        croak "Version must be major.minor.patch but is $version" if $version !~ m{ ^ [1-9][0-9]* [.] [0-9]+ [.] [0-9]+ $ }xsm;
    }

    my $workflow = Local::Workflow->new(
        min_perl_linux      => $self->github_workflow_min_perl_linux,
        min_perl_strawberry => $self->github_workflow_min_perl_strawberry,
    )->create;

    my $workflow_path = path('.github/workflows');
    $workflow_path->mkpath;

    say " ==> Creating Github Actions Workflow";
    $workflow_path->child('test.yml')->spew($workflow);

    return;
}

sub _find_local_test_exception {
    my ( $self, $it ) = @_;

  FILE:
    while ( defined( my $file = $it->() ) ) {
        my $filename = $file->stringify;
        next if !-f $filename;
        next if $filename !~ m{ \Q.t\E $ }xsm;

        my $prereqs = Perl::PrereqScanner->new->scan_file($filename)->as_string_hash;

        return $filename if exists $prereqs->{'Local::Test::Exception'};
    }

    return;
}

sub _local_test_exception {
    my ($self) = @_;

    say ' ==> Local::Test::Exception';

    my $ltt_in_t  = path('t')->child('lib/Local/Test/Exception.pm');
    my $ltt_in_xt = path('xt')->child('lib/Local/Test/Exception.pm');

    my $filename_in_t = $self->_find_local_test_exception( path('t')->iterator( { recurse => 1 } ) );
    my $filename_in_xt;
    if ( defined $filename_in_t ) {
        say "  => $filename_in_t";
    }
    else {
        $filename_in_xt = $self->_find_local_test_exception( path('xt')->iterator( { recurse => 1 } ) );
        if ( defined $filename_in_xt ) {
            say "  => $filename_in_xt";
        }
    }

    if ( defined $filename_in_t ) {
        say "  => creating $ltt_in_t from template";
        $ltt_in_t->parent->mkpath;
        path( $self->common_dir )->child('t_lib_Local_Test_Exception/Exception.pm')->copy($ltt_in_t);
    }
    else {
        if ( $ltt_in_t->is_file ) {
            say "  => unlinking $ltt_in_t";
            $ltt_in_t->remove;
        }
    }

    if ( defined $filename_in_xt ) {
        say "  => creating $ltt_in_xt from template";
        $ltt_in_xt->parent->mkpath;
        path( $self->common_dir )->child('t_lib_Local_Test_Exception/Exception.pm')->copy($ltt_in_xt);
    }
    else {
        if ( $ltt_in_xt->is_file ) {
            say "  => unlinking $ltt_in_xt";
            $ltt_in_xt->remove;
        }
    }

    return;
}

sub _find_local_test_tempdir {
    my ( $self, $it ) = @_;

  FILE:
    while ( defined( my $file = $it->() ) ) {
        my $filename = $file->stringify;
        next if !-f $filename;
        next if $filename !~ m{ \Q.t\E $ }xsm;

        my $prereqs = Perl::PrereqScanner->new->scan_file($filename)->as_string_hash;

        return $filename if exists $prereqs->{'Local::Test::TempDir'};
    }

    return;
}

sub _local_test_tempdir {
    my ($self) = @_;

    say ' ==> Local::Test::TempDir';

    my $ltt_in_t  = path('t')->child('lib/Local/Test/TempDir.pm');
    my $ltt_in_xt = path('xt')->child('lib/Local/Test/TempDir.pm');

    my $filename_in_t = $self->_find_local_test_tempdir( path('t')->iterator( { recurse => 1 } ) );
    my $filename_in_xt;
    if ( defined $filename_in_t ) {
        say "  => $filename_in_t";
    }
    else {
        $filename_in_xt = $self->_find_local_test_tempdir( path('xt')->iterator( { recurse => 1 } ) );
        if ( defined $filename_in_xt ) {
            say "  => $filename_in_xt";
        }
    }

    if ( defined $filename_in_t ) {
        say "  => creating $ltt_in_t from template";
        $ltt_in_t->parent->mkpath;
        path( $self->common_dir )->child('t_lib_Local_Test_TempDir/TempDir.pm')->copy($ltt_in_t);
    }
    else {
        if ( $ltt_in_t->is_file ) {
            say "  => unlinking $ltt_in_t";
            $ltt_in_t->remove;
        }
    }

    if ( defined $filename_in_xt ) {
        say "  => creating $ltt_in_xt from template";
        $ltt_in_xt->parent->mkpath;
        path( $self->common_dir )->child('t_lib_Local_Test_TempDir/TempDir.pm')->copy($ltt_in_xt);
    }
    else {
        if ( $ltt_in_xt->is_file ) {
            say "  => unlinking $ltt_in_xt";
            $ltt_in_xt->remove;
        }
    }

    return;
}

sub _remove_files {
    my ($self) = @_;

  FILE:
    for my $file ( qw(.appveyor.yml .travis.yml), glob q{xt/*/*.t} ) {
        next FILE if !-f $file;

        unlink $file or croak "Cannot remove file $file: $!";
    }

    return;
}

sub update_project {
    my ($self) = @_;

    say '===> ', $self->repo;

    #$self->_clone_or_update_project;

    $self->_remove_files;

    if ( $self->github_workflow ) {
        $self->_create_github_workflow;
    }

    $self->_copy_files_from_submodule_to_project;

    $self->_local_test_exception;
    $self->_local_test_tempdir;

    return;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
