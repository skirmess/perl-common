package Dist::Zilla::Plugin::Author::SKIRMESS::RemoveDevelopPrereqs;

use 5.006;
use strict;
use warnings;

use Moose;

with qw(Dist::Zilla::Role::PrereqSource);

# Consumed by Dist::Zilla::Plugin::Author::SKIRMESS::CPANFile
has _develop => (
    is  => 'rw',
    isa => 'HashRef',
);

use namespace::autoclean;

sub develop_prereqs {
    my ($self) = @_;

    return $self->_develop;
}

sub register_prereqs {
    my ($self) = @_;

    my $prereqs = $self->zilla->prereqs;
    my $raw     = $prereqs->as_string_hash;

    return if !exists $raw->{develop};

    my $develop = $raw->{develop};
    $self->_develop($develop);

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
