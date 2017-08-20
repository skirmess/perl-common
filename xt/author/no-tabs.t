#!perl

use strict;
use warnings;

BEGIN {
    if ( !exists $ENV{AUTHOR_TESTING} ) {
        print "1..0 # SKIP these tests are for testing by the author\n";
        exit 0;
    }
}

use Test::NoTabs;

all_perl_files_ok( grep { -d } qw( bin lib t xt ) );

# vim: ts=4 sts=4 sw=4 et: syntax=perl
