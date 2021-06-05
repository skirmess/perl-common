#!perl

# {{ $generated }}

use 5.006;
use strict;
use warnings;

use FindBin qw($RealBin);
use Path::Tiny;

use Test::PerlTidy::XTFiles;

Test::PerlTidy::XTFiles->new(
    mute       => 1,
    perltidyrc => path($RealBin)->parent(2)->child('.perltidyrc')->stringify,
)->all_files_ok;
