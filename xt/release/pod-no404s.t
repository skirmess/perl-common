#!perl

use strict;
use warnings;

BEGIN {
    if ( !exists $ENV{RELEASE_TESTING} ) {
        print "1..0 # SKIP these tests are for release testing\n";
        exit 0;
    }

    if ( exists $ENV{AUTOMATED_TESTING} ) {
        print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
        exit 0;
    }
}

use Test::More;
use Test::Pod::No404s;

all_pod_files_ok();

# vim: ts=4 sts=4 sw=4 et: syntax=perl
