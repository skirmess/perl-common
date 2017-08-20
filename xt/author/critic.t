#!perl

use strict;
use warnings;

BEGIN {
    if ( !exists $ENV{AUTHOR_TESTING} ) {
        print "1..0 # SKIP these tests are for testing by the author\n";
        exit 0;
    }
}

use File::Spec;

my $rcfile;

BEGIN {
    $rcfile = File::Spec->catfile(qw(xt author perlcriticrc));
}

use Perl::Critic::Utils qw(all_perl_files);
use Test::More;
use Test::Perl::Critic ( -profile => $rcfile );

my @dirs = qw(bin lib t xt);

my @ignores = ();

my %ignore = map { $_ => 1 } @ignores;

my @files = grep { !exists $ignore{$_} } all_perl_files(@dirs);

if ( @files == 0 ) {
    BAIL_OUT('no files to criticize found');
}

all_critic_ok(@files);

# vim: ts=4 sts=4 sw=4 et: syntax=perl
