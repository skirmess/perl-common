package Dist::Zilla::Plugin::Author::SKIRMESS::CPANFile;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.000';

use Moose;

with qw(Dist::Zilla::Role::AfterBuild);

use Module::CPANfile;

has develop_prereqs => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

use namespace::autoclean;

sub after_build {
    my ($self) = @_;

    my $zilla   = $self->zilla;
    my $prereqs = $zilla->prereqs;
    my $pre     = $prereqs->as_string_hash;

    $self->log_fatal('develop prereqs were not removed, please use Author::SKIRMESS::MoveDevelopPrereqsToStash') if exists $pre->{develop};

    # Created by Dist::Zilla::Plugin::Author::SKIRMESS::RemoveDevelopPrereqs
    my $plugin = $self->zilla->plugin_named( $self->develop_prereqs );
    $self->log_fatal( [ q{Plugin '%s' does not exist}, $self->develop_prereqs ] ) if !defined $plugin;

    my $develop = $plugin->develop_prereqs;
    if ( !defined $develop ) {
        $self->log( [ q{No develop dependencies received from '%s'}, $self->develop_prereqs ] );
    }
    else {
        $pre->{develop} = $develop;
    }

    Module::CPANfile->from_prereqs($pre)->save('cpanfile');

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::SKIRMESS::CPANFile - create a cpanfile in the project

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
