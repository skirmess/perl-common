#!perl

# {{ $generated }}

use 5.006;
use strict;
use warnings;

use Test::CPAN::Meta 0.12;
use XT::Util;

if ( __CONFIG__()->{':skip'} ) {
    print "1..0 # SKIP disabled\n";
    exit 0;
}

meta_yaml_ok();
