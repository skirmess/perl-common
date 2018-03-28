#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

# CPANPLUS is used by Test::Pod::LinkCheck but is not a dependency. The
# require on CPANPLUS is only here for dzil to pick it up and add it as a
# develop dependency to the cpanfile.
require CPANPLUS;

use Test::Pod::LinkCheck;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

Test::Pod::LinkCheck->new->all_pod_ok;
