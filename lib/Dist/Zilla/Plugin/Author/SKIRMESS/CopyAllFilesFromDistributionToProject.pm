package Dist::Zilla::Plugin::Author::SKIRMESS::CopyAllFilesFromDistributionToProject;

use 5.006;
use strict;
use warnings;

use Moose;

with qw(
  Dist::Zilla::Role::AfterBuild
  Dist::Zilla::Role::AfterRelease
);

use File::Compare;
use File::Copy;
use Path::Tiny;

sub mvp_multivalue_args { return (qw( skip_file )) }

has skip_file => (
    is      => 'ro',
    isa     => 'ArrayRef[Str]',
    default => sub { [] },
);

use namespace::autoclean;

sub after_build {
    my ( $self, $data ) = @_;

    $self->log_fatal(q{'build_root' not defined}) if !exists $data->{build_root};

    return $self->_copy_all_files_back( $data->{build_root} );
}

sub after_release {
    my ($self) = @_;

    my $zilla    = $self->zilla;
    my $built_in = $zilla->ensure_built;

    return $self->_copy_all_files_back($built_in);
}

sub _copy_all_files_back {
    my ( $self, $src_dir ) = @_;

    my %skip = map { $_ => 1 } @{ $self->skip_file };

    $self->log_Fatal("Not a directory: $src_dir") if !-d $src_dir;

    $src_dir = path($src_dir);
    my $it = $src_dir->iterator( { recurse => 1 } );

  FILE:
    while ( defined( my $file = $it->() ) ) {
        next FILE if -d $file;

        my $target = $file->relative($src_dir);
        next FILE if exists $skip{$target};

        $self->log_fatal("File '$file' is not a regular file") if -l $file || !-f _;

        if ( -f $target ) {
            my $rc = compare( $file, $target );

            if ( $rc == 0 ) {
                $self->log_debug("File '$file' and '$target' are identical.");
                next FILE;
            }

            if ( $rc == -1 ) {
                $self->log_fatal("Unable to compare '$file' with '$target': $!");
            }
        }

        if ( copy( $file, $target ) != 1 ) {
            $self->log_fatal("Copy $file to $target failed: $!");
        }

        $self->log("Copy $file to $target");
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
