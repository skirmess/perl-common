package Dist::Zilla::Plugin::Author::SKIRMESS::MoveDevelopPrereqsToStash;

use 5.006;
use strict;
use warnings;

our $VERSION = '0.033';

use Moose;

with qw(
  Dist::Zilla::Role::PrereqSource
  Dist::Zilla::Role::RegisterStash
);

use namespace::autoclean;

sub register_prereqs {
    my ($self) = @_;

    my $prereqs = $self->zilla->prereqs;
    my $raw     = $prereqs->as_string_hash;

    return if !exists $raw->{develop};

    my $develop = $raw->{develop};
    if ( defined $develop ) {
        $self->_register_stash( '%Author::SKIRMESS::develop_prereqs' => $develop );
    }

    for my $phase ( keys %{$develop} ) {
        for my $module ( keys %{ $develop->{$phase} } ) {
            $prereqs->requirements_for( 'develop', $phase )->clear_requirement($module);
        }
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
