package Dist::Zilla::Plugin::Author::SKIRMESS::RemoveDevelopPrereqs;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.000';

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

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::SKIRMESS::RemoveDevelopPrereqs - remove the develop prereqs because they make no sense in the META.* files

=head1 VERSION

Version 1.000

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/skirmess/dzil-inc/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/skirmess/dzil-inc>

  git clone https://github.com/skirmess/dzil-inc.git

=head1 AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
