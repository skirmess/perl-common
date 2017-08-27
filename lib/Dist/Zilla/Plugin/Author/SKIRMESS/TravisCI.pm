package Dist::Zilla::Plugin::Author::SKIRMESS::TravisCI;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.005';

use Moose;

with qw(
  Dist::Zilla::Role::BeforeBuild
);

use Path::Tiny;

use namespace::autoclean;

sub before_build {
    my ($self) = @_;

    my $travis_yml = <<'TRAVIS_YML';
language: perl
perl:
  - '5.26'
  - '5.24'
  - '5.22'
  - '5.20'
  - '5.18'
  - '5.16'
  - '5.14'
  - '5.12'
  - '5.10'
  - '5.8'
before_install:
  - export AUTOMATED_TESTING=1 AUTHOR_TESTING=1
install:
  - cpanm --quiet --installdeps --notest --skip-satisfied --with-develop .
script:
  - perl Makefile.PL && make test
  - test -d xt/author && prove -lr xt/author
  - rm -f xt/release/manifest.t
  - test -d xt/release && prove -lr xt/release
TRAVIS_YML

    path('.travis.yml')->spew($travis_yml);

    return;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
