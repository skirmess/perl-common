package Dist::Zilla::Plugin::Author::SKIRMESS::Test::Load;

use 5.006;
use strict;
use warnings;

our $VERSION = '1.000';

use Moose;

with(
    'Dist::Zilla::Role::FileFinderUser' => {
        method           => 'found_module_files',
        finder_arg_names => ['module_finder'],
        default_finders  => [':InstallModules'],
    },
    'Dist::Zilla::Role::FileFinderUser' => {
        method           => 'found_script_files',
        finder_arg_names => ['script_finder'],
        default_finders  => [':PerlExecFiles'],
    },
    'Dist::Zilla::Role::FileGatherer',
    'Dist::Zilla::Role::TextTemplate',
);

use Dist::Zilla::File::InMemory;
use File::Spec;

use namespace::autoclean;

has _generated_string => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Automatically generated file; DO NOT EDIT.',
);

sub gather_files {
    my ($self) = @_;

    my $file = Dist::Zilla::File::InMemory->new(
        {
            name    => 't/00-load.t',
            content => $self->fill_in_string(
                $self->_t_load,
                {
                    plugin => \$self,
                },
            ),
        },
    );

    $self->add_file($file);

    return;
}

sub _t_load {
    my ($self) = @_;

    my %use_lib_args = (
        lib  => undef,
        q{.} => undef,
    );

    my @modules;
  MODULE:
    for my $module ( map { $_->name } @{ $self->found_module_files() } ) {
        next MODULE if $module =~ m{ [.] pod $}xsm;

        my @dirs = File::Spec->splitdir($module);
        if ( $dirs[0] eq 'lib' && $dirs[-1] =~ s{ [.] pm $ }{}xsm ) {
            shift @dirs;
            push @modules, join q{::}, @dirs;
            $use_lib_args{lib} = 1;
            next MODULE;
        }

        $use_lib_args{q{.}} = 1;
        push @modules, $module;
    }

    my @scripts = map { $_->name } @{ $self->found_script_files() };
    if (@scripts) {
        $use_lib_args{q{.}} = 1;
    }

    my $content = <<'T_OO_LOAD_T';
#!perl

use 5.006;
use strict;
use warnings;

# {{ $plugin->_generated_string() }}

use Test::More 0.88;

T_OO_LOAD_T

    if ( !@scripts && !@modules ) {
        $content .= qq{BAIL_OUT("No files found in distribution");\n};

        return $content;
    }

    $content .= 'use lib qw(';
    if ( defined $use_lib_args{lib} ) {
        if ( defined $use_lib_args{q{.}} ) {
            $content .= 'lib .';
        }
        else {
            $content .= 'lib';
        }
    }
    else {
        $content .= q{.};
    }
    $content .= ");\n\n";

    $content .= "my \@modules = qw(\n";

    for my $module ( @modules, @scripts ) {
        $content .= "  $module\n";
    }
    $content .= <<'T_OO_LOAD_T';
);

plan tests => scalar @modules;

for my $module (@modules) {
    require_ok($module) || BAIL_OUT();
}
T_OO_LOAD_T

    return $content;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Author::SKIRMESS::Test::Load - create the t/00-load.t test

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

This software is Copyright (c) 2017-2019 by Sven Kirmess.

This is free software, licensed under:

  The (two-clause) FreeBSD License

=cut

# vim: ts=4 sts=4 sw=4 et: syntax=perl
