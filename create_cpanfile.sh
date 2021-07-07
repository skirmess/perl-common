#!/usr/bin/bash

# Perl::PrereqScanner::NotQuiteLite
# Module::CPANfile

cd -- "$(dirname -- "$0")" || exit 1

grep '^\[' xt/author/perlcriticrc | sed -e 's,^\[,use Perl::Critic::Policy::,' -e 's,\],;,' > xt/tmp.pm
scan-perl-prereqs-nqlite -cpanfile bin lib t xt > cpanfile || exit 1
rm -f xt/tmp.pm

