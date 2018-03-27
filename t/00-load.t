#!perl

use 5.006;
use strict;
use warnings;

# Automatically generated file; DO NOT EDIT.

use Test::More;

use lib qw(lib);

my @modules = qw(
  Dist::Zilla::Plugin::Author::SKIRMESS::CPANFile
  Dist::Zilla::Plugin::Author::SKIRMESS::CheckCopyrightYear
  Dist::Zilla::Plugin::Author::SKIRMESS::CheckFilesInDistribution
  Dist::Zilla::Plugin::Author::SKIRMESS::CopyAllFilesFromDistributionToProject
  Dist::Zilla::Plugin::Author::SKIRMESS::InsertVersion
  Dist::Zilla::Plugin::Author::SKIRMESS::ProjectSkeleton
  Dist::Zilla::Plugin::Author::SKIRMESS::RemoveDevelopPrereqs
  Dist::Zilla::Plugin::Author::SKIRMESS::RunExtraTests::FromProject
  Dist::Zilla::Plugin::Author::SKIRMESS::Test::Load
  Dist::Zilla::PluginBundle::Author::SKIRMESS
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
