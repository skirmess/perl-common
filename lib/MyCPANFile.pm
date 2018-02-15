package MyCPANFile;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.033';

use Moose;

with qw(Dist::Zilla::Role::AfterBuild);

use Module::CPANfile;

use namespace::autoclean;

sub after_build {
    my ($self) = @_;

    my $zilla   = $self->zilla;
    my $prereqs = $zilla->prereqs;

    Module::CPANfile->from_prereqs( $prereqs->as_string_hash )->save('cpanfile');

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
