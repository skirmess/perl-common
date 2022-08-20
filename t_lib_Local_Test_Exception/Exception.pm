# vim: ts=4 sts=4 sw=4 et: syntax=perl
#
# !!! RUN "dzil build" TO UPDATE LICENSE !!!
#

use 5.006;
use strict;
use warnings;

package Local::Test::Exception;

our $VERSION = '0.001';

# Support Exporter < 5.57
require Exporter;
our @ISA       = qw(Exporter);    ## no critic (ClassHierarchies::ProhibitExplicitISA)
our @EXPORT_OK = qw(exception);

sub exception(&) {
    my ($code) = @_;

    my $e;
    {
        local $@;    ## no critic (Variables::RequireInitializationForLocalVars)
        if ( !eval { $code->(); 1; } ) {
            $e = $@;
        }
    }

    return $e;
}

1;
