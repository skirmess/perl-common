package Local::Update;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

use File::pushd;
use Git::Wrapper;
use JSON::PP qw(decode_json);
use Path::Tiny qw(path);

use Local::PerlCriticRc;
use Local::Repository;

use namespace::autoclean 0.09;

has common_dir => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { path(__FILE__)->absolute->parent(3); },
    init_arg => undef,
);

sub run {
    my ($self) = @_;

    my ($remote) = Git::Wrapper->new(q{.})->remote(qw{get-url --push origin});
    die 'Cannot get the remote' if !defined $remote;

    $remote =~ s{ ^ git[@]github[.]com:skirmess/ }{}xsm or die "Unknown remote $remote";

    die "Cwd is not a dzil working directory" if !-f 'dist.ini';

    {
        my $wd = pushd( $self->common_dir->stringify );

        # Create new perlcriticrc in templates
        Local::PerlCriticRc->create('templates/xt/author/perlcriticrc');
    }

    # Update the repo
    my $repos_file = $self->common_dir->child('repos.json');
    my $repos      = decode_json( $repos_file->slurp_utf8 );
    $repos_file->spew_utf8( JSON::PP->new->pretty(1)->canonical(1)->encode($repos) );
  REPO:
    for my $repo_ref ( @{$repos} ) {
        my $this_remote = $repo_ref->{push_url};
        $this_remote =~ s{ ^ git[@]github[.]com:skirmess/ }{}xsm or die "Unknown remote $this_remote";

        next REPO if $this_remote ne $remote;

        my %ref = %{$repo_ref};
        $ref{common_dir} = $self->common_dir->stringify;

        Local::Repository->new( \%ref )->update_project();

        last REPO;
    }

    say "OK.";

    exit 0;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
