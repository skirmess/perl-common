#!perl

use strict;
use warnings;

BEGIN {
    if ( !exists $ENV{AUTHOR_TESTING} ) {
        print "1..0 # SKIP these tests are for testing by the author\n";
        exit 0;
    }
}

use Test::More;
use Test::Spelling 0.12;
use Pod::Wordlist;

add_stopwords(qw(Sven Kirmess));

add_stopwords(<DATA>);

all_pod_files_spelling_ok(qw( bin lib ));
__DATA__
SKIRMESS
dist
