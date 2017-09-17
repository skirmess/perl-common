#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.018

use Test::More;
use Test::Pod::LinkCheck;

Test::Pod::LinkCheck->new()->all_pod_ok();
