package Local::Update;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

use Carp;
use JSON::PP qw(decode_json);
use Path::Tiny qw(path);

use Local::PerlCriticRc;
use Local::Repository;

use namespace::autoclean 0.09;

has base_dir => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { path(__FILE__)->absolute->parent(3); },
    init_arg => undef,
);

sub run {
    my ($self) = @_;

    chdir $self->base_dir or confess "chdir failed: $!";

    # Create new perlcriticrc in templates
    Local::PerlCriticRc->create('templates/xt/author/perlcriticrc');

    # Update the repos
    my $repos = decode_json( path('repos.json')->slurp_utf8 );
    path('repos.json')->spew( JSON::PP->new->pretty(1)->canonical(1)->encode($repos) );
    for my $repo_ref ( @{$repos} ) {
        Local::Repository->new($repo_ref)->update_project;
    }

    exit 0;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
