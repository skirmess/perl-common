package Dist::Zilla::Role::Author::SKIRMESS::Resources;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.000';

use Moose::Role;

use namespace::autoclean;

sub bugtracker {
    my ($self) = @_;

    my $resources = $self->_get_resources;

    return if !defined $resources->{bugtracker} || ref $resources->{bugtracker} ne ref {};
    return if !defined $resources->{bugtracker}->{web} || ref $resources->{bugtracker}->{web} ne ref q{};

    return $resources->{bugtracker}->{web};
}

sub homepage {
    my ($self) = @_;

    my $resources = $self->_get_resources;

    return if !defined $resources->{homepage} || ref $resources->{homepage} ne ref q{};

    return $resources->{homepage};
}

sub repository {
    my ($self) = @_;

    my $resources = $self->_get_resources;

    return if !defined $resources->{repository} || ref $resources->{repository} ne ref {};
    return if !defined $resources->{repository}->{url} || ref $resources->{repository}->{url} ne ref q{};

    return $resources->{repository}->{url};
}

sub _get_resources {
    my ($self) = @_;

    my $distmeta = $self->zilla->distmeta;

    return if !defined $distmeta;
    return if !defined $distmeta->{resources} || ref $distmeta->{resources} ne ref {};

    return $distmeta->{resources};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::Author::SKIRMESS::Resources - access the distmeta resources

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

This software is Copyright (c) 2017-2020 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
