#!perl

use strict;
use warnings;

BEGIN {
    if ( !exists $ENV{AUTHOR_TESTING} ) {
        print "1..0 # SKIP these tests are for testing by the author\n";
        exit 0;
    }
}

use Test::CPAN::Meta;

meta_yaml_ok();

# vim: ts=4 sts=4 sw=4 et: syntax=perl
