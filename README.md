# NAME

Dist::Zilla::PluginBundle::Author::SKIRMESS - Dist::Zilla configuration the way SKIRMESS does it

# VERSION

Version 1.000

# SYNOPSIS

## Create a new dzil project

Create a new repository on Github and clone it.

    $ git submodule add ../dzil-inc.git
    $ git commit -m 'added Author::SKIRMESS plugin bundle as git submodule'

    # in dist.ini
    [lib]
    lib = dzil-inc/lib

    [@Author::SKIRMESS]

## Clone a project which already contains this submodule

    $ git clone https://github.com/skirmess/...
    $ git submodule update --init

    # To update dzil-inc
    $ cd dzil-inc && git checkout master

## Update the submodule

    $ cd dzil-inv && git pull

# DESCRIPTION

This is a [Dist::Zilla](https://metacpan.org/pod/Dist::Zilla) PluginBundle.

The bundle will not be released on CPAN, instead it is designed to be
included as Git submodule in the project that will use it.

# USAGE

To use this PluginBundle, include it as Git submodule in your project and
add it to your dist.ini. You can provide the following options:

- `set_script_shebang` - this indicates whether `SetScriptShebang` should be used or not

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/skirmess/dzil-inc/issues](https://github.com/skirmess/dzil-inc/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software. The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/skirmess/dzil-inc](https://github.com/skirmess/dzil-inc)

    git clone https://github.com/skirmess/dzil-inc.git

# AUTHOR

Sven Kirmess <sven.kirmess@kzone.ch>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2017-2018 by Sven Kirmess.

This is free software, licensed under:

    The (two-clause) FreeBSD License
