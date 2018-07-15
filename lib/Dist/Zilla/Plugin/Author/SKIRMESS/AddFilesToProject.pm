package Dist::Zilla::Plugin::Author::SKIRMESS::AddFilesToProject;

use 5.010;
use strict;
use warnings;

our $VERSION = '1.000';

use Moose;

with qw(
  Dist::Zilla::Role::AfterBuild
);

use Path::Tiny;
use Text::Template qw(fill_in_file);

use namespace::autoclean;

sub mvp_multivalue_args {
    return qw(file);
}

has _config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { +{} },
);

has delim => (
    is       => 'ro',
    isa      => 'ArrayRef',
    lazy     => 1,
    init_arg => undef,
    default  => sub { [qw(  {{  }}  )] },
);

has file => (
    is      => 'ro',
    isa     => 'ArrayRef',
    default => sub { [] },
);

has prefix => (
    is      => 'ro',
    isa     => 'Str',
    default => q{},
);

has root => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

around BUILDARGS => sub {
    my $orig = shift;
    my ( $class, @arg ) = @_;

    my $args    = $class->$orig(@arg);
    my %retargs = %{$args};

    for my $config ( grep { m{ ^ config [.] }xsm } keys %retargs ) {
        my $value = delete $retargs{$config};
        $config =~ s{ ^ config [.] }{}xsm;
        $retargs{_config}->{$config} = $value;
    }

    return \%retargs;
};

sub after_build {
    my ($self) = @_;

    my @files = @{ $self->file };
    return if !@files;

    my $zilla = $self->zilla;

    my $project_root = $zilla->root;

    $self->log_fatal('root must be defined') if !$self->root;
    my $root = path( $self->root )->absolute($project_root);
    $self->log_fatal("root dir '$root' must exist") if !-d $root;

    my $prefix = $self->prefix ? path( $self->prefix )->absolute($project_root) : path($project_root)->absolute;

    my %config = %{ $self->_config };
    $config{dist}   = \$zilla;
    $config{plugin} = \$self;

  FILE:
    for my $file (@files) {
        $self->log_fatal("File '$file' is not relative") if !path($file)->is_relative;

        my $content = fill_in_file(
            $root->child($file),
            BROKEN     => sub { my %hash = @_; $self->log_fatal( $hash{error} ); },
            DELIMITERS => $self->delim,
            STRICT     => 1,
            HASH       => \%config,
        );

        if ( !defined $content ) {
            $self->log_fatal("Filling in the template returned undef for file '$file': $Text::Template::ERROR");
        }

        my $target        = $prefix->child($file);
        my $target_parent = $target->parent;

        if ( !-d $target_parent ) {
            my $target_parent_relative = $target_parent->relative($project_root);
            $self->log_fatal("'$target_parent_relative' exists but is not a directory") if -e $target_parent;

            $self->log_debug("Creating dir '$target_parent_relative'");
            $target_parent->mkpath;
        }

        my $target_relative = $target->relative($project_root);
        $self->log_debug( "Creating file '$target_relative' from template '" . $root->child($file)->relative($project_root) . q{'} );

        $target->spew($content);
    }

    return;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::SKIRMESS::AddFilesToProject - Add files to the project from templates

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
