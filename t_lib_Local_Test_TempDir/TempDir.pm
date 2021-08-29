package Local::Test::TempDir;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.001';

use Carp;
use Cwd        ();
use File::Path ();
use File::Spec ();

use Exporter 5.57 qw(import);
our @EXPORT_OK = qw(tempdir);

{
    my $temp_dir_base;

    sub _init {
        return if defined $temp_dir_base;

        my $root_dir = Cwd::getcwd();
        croak "Cannot get cwd: $!" if !defined $root_dir;

        $temp_dir_base = File::Spec->catdir( $root_dir, 'tmp' );
        if ( !-d $temp_dir_base ) {
            mkdir $temp_dir_base or croak "Cannot create directory $temp_dir_base $!";
        }

        ( my $dirname = $0 ) =~ tr{:\\/.}{_};
        $temp_dir_base = File::Spec->catdir( $temp_dir_base, $dirname );
        if ( !-e $temp_dir_base ) {
            mkdir $temp_dir_base or croak "Cannot create directory $temp_dir_base $!";
        }
        elsif ( -l $temp_dir_base || !-d _ ) {
            croak "Not a directory $temp_dir_base";
        }
        else {
            File::Path::remove_tree( $temp_dir_base, { keep_root => 1 } );
        }

        return;
    }

    my %counter;

    sub tempdir {
        my $label = defined( $_[0] ) ? $_[0] : 'default';
        $label =~ tr{a-zA-Z0-9_-}{_}cs;

        if ( exists $counter{$label} ) {
            $counter{$label}++;
        }
        else {
            $counter{$label} = '0';
        }

        $label = "${label}_$counter{$label}";

        _init();

        my $tempdir = File::Spec->catdir( $temp_dir_base, $label );
        mkdir $tempdir or croak "Cannot create directory: $!";

        return $tempdir;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Local::Test::TempDir - create temporary directories to be used by tests

=head1 VERSION

Version 0.003

=head1 SYNOPSIS

    use Local::Test::TempDir qw(tempdir);
    my $tempdir = tempdir();

    my $tempdir = tempdir('my_label');

=head1 DESCRIPTION

TBD

=head1 USAGE

=head2 tempdir( ARGS )

=head1 SEE ALSO

L<Test::TempDir::Tiny>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/Test-RequiredMinimumDependencyVersion/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/Test-RequiredMinimumDependencyVersion>

  git clone https://github.com/skirmess/Test-RequiredMinimumDependencyVersion.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2018-2021 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
