package Local::Role::Template;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo::Role;

use Carp;
use Text::Template ();

# Text to mention that a file is automatically generated.
use constant GENERATED_TEXT => 'Automatically generated file; DO NOT EDIT.';

# Text::Template delimiter
use constant TEXT_TEMPLATE_DELIM => [qw(  {{  }}  )];

sub fill_in_file {
    my ( $self, $filename ) = @_;

    my %config = (
        plugin    => \$self,
        generated => GENERATED_TEXT(),
    );

    my $content = Text::Template::fill_in_file(
        $filename,
        BROKEN     => sub { my %hash = @_; confess $hash{error}; },
        DELIMITERS => TEXT_TEMPLATE_DELIM,
        STRICT     => 1,
        HASH       => \%config,
    );

    return $content;
}

sub fill_in_string {
    my ( $self, $string ) = @_;

    my %config = (
        plugin    => \$self,
        generated => GENERATED_TEXT,
    );

    my $content = Text::Template::fill_in_string(
        $string,
        BROKEN     => sub { my %hash = @_; confess $hash{error}; },
        DELIMITERS => TEXT_TEMPLATE_DELIM,
        STRICT     => 1,
        HASH       => \%config,
    );

    return $content;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
