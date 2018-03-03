package Dist::Zilla::Plugin::Author::SKIRMESS::CPANFile;

use 5.006;
use strict;
use warnings;

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

# vim: ts=4 sts=4 sw=4 et: syntax=perl
