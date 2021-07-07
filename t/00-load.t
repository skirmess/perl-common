#!perl

use 5.006;
use strict;
use warnings;

# this test was generated with
# Dist::Zilla::Plugin::Author::SKIRMESS::RepositoryBase 0.032

use Test::More 0.88;

use lib qw(lib .);

my @modules = qw(
  Local::PerlCriticRc
  Local::Repository
  Local::Role::Template
  Local::Update
  Local::Workflow
  bin/update.pl
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
