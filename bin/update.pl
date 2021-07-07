#!/usr/bin/env perl

use 5.010;
use strict;
use warnings;

use Path::Tiny;

use lib path(__FILE__)->realpath->absolute->parent(2)->child('lib')->stringify;

use Local::Update;

if ( !caller ) {
    Local::Update->new->run;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
