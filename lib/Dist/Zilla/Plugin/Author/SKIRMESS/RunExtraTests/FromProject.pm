package Dist::Zilla::Plugin::Author::SKIRMESS::RunExtraTests::FromProject;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.033';

use Moose;

with qw(
  Dist::Zilla::Role::BeforeBuild
  Dist::Zilla::Role::TestRunner
);

use App::Prove ();
use Dist::Zilla::Types qw(Path);
use File::pushd ();
use Path::Tiny;

sub mvp_multivalue_args { return (qw( skip_build skip_project )) }

has skip_build => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has skip_project => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has _project_root => (
    is  => 'rw',
    isa => Path,
);

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    $self->_project_root( $self->zilla->root->absolute );

    return;
}

sub test {
    my ( $self, $target, $arg_ref ) = @_;

    # Fail if the dist hasn't been built yet
    $self->log_fatal(q{Distribution isn't built yet. Please ensure that you place 'RunExtraTests::FromRepository' after your other test runners (e.g. 'MakeMaker')}) if !-d 'blib';

    my $project_root  = $self->_project_root;
    my $prove_arg_ref = [ $self->_prove_arg($arg_ref) ];

    my @tests = $self->_xt_tests();

    my $path_to_project_root = path($project_root)->relative(q{.});
    my %skip_build           = map { $_ => 1 } @{ $self->skip_build };
    my @build_tests          = map { $path_to_project_root->child($_)->stringify } grep { !exists $skip_build{$_} } @tests;

    if ( !@build_tests ) {
        $self->log('No xt tests (from prohect) to run against the build');
    }
    else {
        local $ENV{BUILD_TESTING} = 1;
        local $ENV{PROJECT_TESTING};
        delete $ENV{PROJECT_TESTING};

        $self->log('Running xt tests (from project) on build');
        $self->_run_prove( $prove_arg_ref, \@build_tests );
    }

    my %skip_project = map { $_ => 1 } @{ $self->skip_project };
    my @project_tests = grep { !exists $skip_project{$_} } @tests;

    if ( !@project_tests ) {
        $self->log('No xt tests (from project) to run against the project');
    }
    else {
        local $ENV{BUILD_TESTING};
        delete $ENV{BUILD_TESTING};
        local $ENV{PROJECT_TESTING} = 1;

        my $wd = File::pushd::pushd($project_root);

        $self->log('Running xt tests (from project) on project');
        $self->_run_prove( $prove_arg_ref, \@project_tests );
    }

    return;
}

sub _prove_arg {
    my ( $self, $arg_ref ) = @_;

    my @prove = qw( -b );

    my $verbose = $self->zilla->logger->get_debug;
    if ( defined $arg_ref && ref $arg_ref eq ref {} ) {
        if ( exists $arg_ref->{test_verbose} && $arg_ref->{test_verbose} ) {
            $verbose = 1;
        }

        if ( exists $arg_ref->{jobs} ) {
            push @prove, '-j', $arg_ref->{jobs};
        }
    }

    if ($verbose) {
        push @prove, '-v';
    }

    return @prove;
}

sub _run_prove {
    my ( $self, $prove_arg_ref, $tests_ref ) = @_;

    my @cmd = ( @{$prove_arg_ref}, @{$tests_ref} );

    my $app = App::Prove->new;
    $self->log_debug( [ 'running prove with args: %s', join q{ }, @cmd ] );
    $app->process_args(@cmd);
    $app->run or $self->log_fatal('Fatal errors in xt tests');

    return;
}

sub _xt_tests {
    my ($self) = @_;

    # check if the project root we saved during the before build phase exists
    my $project_root = $self->_project_root;
    $self->log_fatal('internal error: _project_root is not defined') if !defined $project_root;
    $self->log_fatal("internal error: _project_root '$project_root' does not exist or is not a directory") if !-d $project_root;

    # Change to the project root (will be restored when $wd goes out of scope)
    my $wd = File::pushd::pushd($project_root);

    # Find all the tests we have to run
    my %xt_child = map { $_ => $_ } grep { -d || m{ [.]t $ }xsm } path('xt')->children;

    if ( !exists $ENV{AUTHOR_TESTING} && !exists $ENV{DZIL_RELEASING} ) {
        delete $xt_child{'xt/author'};
    }

    if ( !exists $ENV{RELEASE_TESTING} && !exists $ENV{DZIL_RELEASING} ) {
        delete $xt_child{'xt/release'};
    }

    if ( !exists $ENV{AUTOMATED_TESTING} ) {
        delete $xt_child{'xt/smoke'};
    }

  XT_CHILD:
    for my $xt_child ( values %xt_child ) {
        next XT_CHILD if -f $xt_child;

        $self->log_fatal("File '$xt_child' in project xt is not a directory nor a regular file") if !-d $xt_child;

        delete $xt_child{"$xt_child"};

        my $it = $xt_child->iterator( { recurse => 1 } );
      FILE:
        while ( defined( my $file = $it->() ) ) {
            next FILE if !-f $file;
            next FILE if $file !~ m{ [.] t $ }xsm;

            $xt_child{"$file"} = $file;
        }
    }

    my @tests = sort { lc $a cmp lc $b } keys %xt_child;
    return @tests;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
