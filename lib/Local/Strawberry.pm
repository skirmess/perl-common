package Local::Strawberry;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.000';

use Moo;
with 'MooX::Singleton';

use Carp;
use HTTP::Tiny;
use JSON::PP qw(decode_json);

use namespace::autoclean 0.09;

has releases => (
    is      => 'ro',
    builder => 1,
);

# Strawberry Perl
use constant WITH_USE_64_BIT_INT          => 1;
use constant WITHOUT_USE_64_BIT_INT       => 2;
use constant STRAWBERRY_PERL_RELEASES_URL => 'http://strawberryperl.com/releases.json';

sub _build_releases {
    my ($self) = @_;

    my $url = STRAWBERRY_PERL_RELEASES_URL;
    say "Downloading '$url'...";
    my $res = HTTP::Tiny->new->get($url);

    confess "Cannot download '$url': $res->{reason}" if !$res->{success};

    my @releases;

  RELEASE:
    for my $release ( @{ decode_json( $res->{content} ) } ) {
        my $version = $release->{version};
        ## no critic (RegularExpressions::RequireDotMatchAnything)
        ## no critic (RegularExpressions::RequireExtendedFormatting)
        ## no critic (RegularExpressions::RequireLineBoundaryMatching)
        my @name = split /\s*\/\s*/, $release->{name};

        confess "Unable to parse name: $release->{name}"                 if ( @name < 3 ) || ( @name > 4 );
        confess "Version '$version' does not version in name '$name[1]'" if $version ne $name[1];
        confess "Unable to parse version '$version'"                     if $version !~ m{ ^ ( ( 5 [.] [1-9][0-9]* ) [.] [0-9]+ ) [.] [0-9]+ $ }xsm;

        my @release = ( $2, $1, $version );    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)

        next RELEASE if !exists $release->{edition}->{zip}->{url};
        push @release, $release->{edition}->{zip}->{url};

        if ( $name[2] eq '64bit' ) {
            push @release, $name[2];
        }
        elsif ( $name[2] eq '32bit' ) {
            push @release, $name[2];

            if ( $name[3] eq 'with USE_64_BIT_INT' ) {
                push @release, WITH_USE_64_BIT_INT;
            }
            elsif ( $name[3] eq 'without USE_64_BIT_INT' ) {
                push @release, WITHOUT_USE_64_BIT_INT;
            }
            else {
                confess "Expect either 'with USE_64_BIT_INT' or 'without USE_64_BIT_INT' but got '$name[3]'";
            }
        }
        else {
            confess "Expected either 32bit or 64bit but got '$name[2]'";
        }

        push @releases, \@release;
    }

    return \@releases;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
