#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::Spelling 0.12;
use Pod::Wordlist;

if ( exists $ENV{AUTOMATED_TESTING} ) {
    print "1..0 # SKIP these tests during AUTOMATED_TESTING\n";
    exit 0;
}

add_stopwords(<DATA>);

all_pod_files_spelling_ok( grep { -d } qw( bin lib t xt ) );
__DATA__
<sven.kirmess@kzone.ch>
AppVeyor
BeforeArchive
CI
Kirmess
MyBundle
RunExtraTests
SKIRMESS
Sven
TravisCI
appveyor
ci
cpanfile
dist
distmeta
osx
perltidy
perltidyrc
travis
whitelisted
xt
