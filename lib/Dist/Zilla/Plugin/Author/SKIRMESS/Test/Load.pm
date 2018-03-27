package Dist::Zilla::Plugin::Author::SKIRMESS::Test::Load;

use 5.006;
use strict;
use warnings;

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

has _generated_string => (
    is      => 'ro',
    isa     => 'Str',
    default => 'Automatically generated file; DO NOT EDIT.',
);

use Dist::Zilla::File::InMemory;

use namespace::autoclean;

sub gather_files {
    my ($self) = @_;

    my $file = Dist::Zilla::File::InMemory->new(
        {
            name    => 't/00-load.t',
            content => $self->fill_in_string(
                $self->_t_load,
                {
                    plugin => \$self,
                }
            ),
        }
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

use Test::More;

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

# vim: ts=4 sts=4 sw=4 et: syntax=perl
