#!perl

use 5.006;
use strict;
use warnings;

use Test::More 0.88;

use lib qw(lib .);

my @modules = qw(
  Local::PerlCriticRc
  Local::Repository
  Local::Role::Template
  Local::Update
  Local::Workflow
  bin/update.pl
  t_lib_Local_Test_TempDir/TempDir.pm
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
