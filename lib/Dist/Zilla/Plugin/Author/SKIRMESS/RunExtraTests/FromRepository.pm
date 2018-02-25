package Dist::Zilla::Plugin::Author::SKIRMESS::RunExtraTests::FromRepository;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.033';

use Moose;

with qw(
  Dist::Zilla::Role::BeforeBuild
  Dist::Zilla::Role::TestRunner
);

use App::Prove;

use Dist::Zilla::Types qw(Path);

has _repository_root => (
    is  => 'rw',
    isa => Path,
);

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    $self->_repository_root( $self->zilla->root->absolute );

    return;
}

sub test {
    my ( $self, $target, $arg ) = @_;

    #
    my $repo = $self->_repository_root;
    if ( !defined $repo ) {
        $self->log_fatal('internal error: repository root is not defined');
    }
    if ( !-d $repo ) {
        $self->log_fatal("internal error: repository root '$repo' does not exist or is not a directory");
    }

    # Fail if the dist hasn't been built yet
    if ( !-d 'blib' ) {
        $self->log_fatal(q{Distribution isn't built yet. Please ensure that you place 'RunExtraTests::FromRepository' after your other test runners (e.g. 'MakeMaker')});
    }

    #
    my $xt_dir = $repo->child('xt');
    if ( !-d $xt_dir ) {
        $self->log('No xt tests exist in the repository');
        return;
    }

    my %things_to_prove = map { $_->relative($repo) => $_ } grep { -d || m{ [.]t $ }xsm } $xt_dir->children;
    if ( !exists $ENV{AUTHOR_TESTING} && !exists $ENV{DZIL_RELEASING} ) {
        delete $things_to_prove{'xt/author'};
    }

    if ( !exists $ENV{RELEASE_TESTING} && !exists $ENV{DZIL_RELEASING} ) {
        delete $things_to_prove{'xt/release'};
    }

    if ( !exists $ENV{AUTOMATED_TESTING} ) {
        delete $things_to_prove{'xt/smoke'};
    }

    my @cmd = sort { lc $a cmp lc $b } map { $_->relative(q{.})->stringify } values %things_to_prove;
    if ( !@cmd ) {
        $self->log('No xt tests to run');
        return;
    }

    unshift @cmd, '-r', '-b';

    my $verbose = $self->zilla->logger->get_debug;
    if ( defined $arg && ref $arg eq ref {} ) {
        if ( exists $arg->{test_verbose} && $arg->{test_verbose} ) {
            $verbose = 1;
        }

        if ( exists $arg->{jobs} ) {
            unshift @cmd, '-j', $arg->{jobs};
        }
    }

    if ($verbose) {
        unshift @cmd, '-v';
    }

    my $app = App::Prove->new;

    $self->log_debug( [ 'running prove with args: %s', join q{ }, @cmd ] );
    $app->process_args(@cmd);
    $app->run or $self->log_fatal('Fatal errors in xt tests');

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
