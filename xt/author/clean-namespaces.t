#!perl

# {{ $generated }}

use 5.006;
use strict;
use warnings;

use Module::Info;
use Test::More 0.88;
use Test::CleanNamespaces;
use Test::XTFiles;
use XT::Util;
use lib ();

if ( __CONFIG__()->{':skip'} ) {
    print "1..0 # SKIP disabled\n";
    exit 0;
}

for my $file ( Test::XTFiles->new->all_module_files() ) {
    note("file    = $file");
    my @packages = Module::Info->new_from_file($file)->packages_inside;

  PACKAGE:
    foreach my $package (@packages) {
        note("package = $package");

        my $info = Module::Info->new_from_module($package);

        if ( !defined $info ) {
            ok( 1, "package is not a module: $package" );
            next PACKAGE;
        }

        local @INC = @INC;
        lib->import( $info->{dir} );

        namespaces_clean($package);
    }
}

done_testing();
