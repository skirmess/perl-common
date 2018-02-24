package Dist::Zilla::Plugin::Author::SKIRMESS::CPANFile;

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
    my $pre     = $prereqs->as_string_hash;

    if ( exists $pre->{develop} ) {
        $self->log_fatal('develop prereqs were not removed, please use Author::SKIRMESS::MoveDevelopPrereqsToStash');
    }

    # Created by Dist::Zilla::Plugin::Author::SKIRMESS::MoveDevelopPrereqsToStash
    my $develop = $self->zilla->stash_named('%Author::SKIRMESS::develop_prereqs');
    if ( !defined $develop ) {
        $self->log('No develop dependencies found in stash');
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
