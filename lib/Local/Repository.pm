package Local::Repository;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

with 'Local::Role::Template';

use Carp;
use CPAN::Perl::Releases qw(perl_versions);
use Git::Wrapper;
use Path::Tiny qw(path);
use version 0.77 ();

use Local::Strawberry;

use namespace::autoclean 0.09;

# AppVeyor
use constant APPVEYOR_CONFIG_FILE         => '.appveyor.yml';
use constant APPVEYOR_AUTHOR_TESTING_PERL => qw(5.24);

# Travis CI
use constant TRAVIS_CI_AUTHOR_TESTING_PERL => qw(5.24);
use constant TRAVIS_CI_CONFIG_FILE         => '.travis.yml';
use constant TRAVIS_CI_OSX_PERL            => qw(5.18);

# new args

has appveyor_earliest_perl => (
    is      => 'ro',
    lazy    => 1,
    default => sub { $_[0]->ci_earliest_perl; },
);

has appveyor_test_on_cygwin => (
    is      => 'ro',
    default => 1,
);

has appveyor_test_on_cygwin64 => (
    is      => 'ro',
    default => 1,
);

has appveyor_test_on_strawberry => (
    is      => 'ro',
    default => 1,
);

# The earliest version of Perl to test on Travis CI and AppVeyor
has ci_earliest_perl => (
    is      => 'ro',
    lazy    => 1,
    default => '5.8',
);

has makefile_pl_exists => (
    is      => 'ro',
    default => 1,
);

has push_url => (
    is => 'ro',
);

has repo => (
    is       => 'ro',
    required => 1,
);

has skip => (
    is      => 'ro',
    default => sub { [] },
);

# -----

has repo_dir => (
    is       => 'ro',
    lazy     => 1,
    default  => sub { path( $_[0]->repo )->basename('.git') },
    init_arg => undef,
);

sub _clone_or_update_project {
    my ($self) = @_;

    if ( !-d 'repos' ) {
        path('repos')->mkpath;
    }

    my $repo_dir_abs = path('repos')->absolute->child( $self->repo_dir );
    my $git          = Git::Wrapper->new($repo_dir_abs);

    if ( -d $repo_dir_abs ) {
        if ( $git->status->is_dirty ) {
            say ' ==> Repository is dirty, skipping update';
            return;
        }

        say ' ==> pulling repo';
        $git->pull;
    }
    else {
        say ' ==> cloning repo';
        $git->clone( $self->repo, $repo_dir_abs );
    }

    my $push_url = $self->push_url;
    if ( defined $push_url ) {
        $git->remote( 'set-url', '--push', 'origin', $push_url );
    }

    return;
}

sub _copy_files_from_submodule_to_project {
    my ($self) = @_;

    say ' ==> Copy files to project';

    my $it = path('templates')->iterator( { recurse => 1 } );

    my %skip = map { $_ => 1 } @{ $self->skip };
  FILE:
    while ( defined( my $file_abs = $it->() ) ) {
        next FILE if -l $file_abs || !-f _;

        my $file = $file_abs->relative( path('templates') );
        confess "File '$file' is not relative" if !$file->is_relative;

        if ( exists $skip{$file} ) {
            say "Skipping file $file";
            next FILE;
        }

        my $content = $self->fill_in_file( $file_abs->stringify );

        confess "Filling in the template returned undef for file '$file': $Text::Template::ERROR" if !defined $content;

        my $target        = path('repos')->child( $self->repo_dir )->child($file);
        my $target_parent = $target->parent;

        if ( !-d $target_parent ) {
            confess "'$target_parent' exists but is not a directory" if -e $target_parent;

            say "Creating dir '$target_parent'";
            $target_parent->mkpath;
        }

        say "Creating file '$target' from template '" . $file_abs . q{'};

        $target->spew($content);
    }

    return;
}

sub _create_appveyor_config {
    my ($self) = @_;

    my $file = path('repos')->child( $self->repo_dir )->child(APPVEYOR_CONFIG_FILE);
    say " ==> Creating file $file (AppVeyor config file)";

    # https://github.com/rjbs/Data-UUID/issues/24
    # Create the c:\tmp directory because Data::UUID can't be built on
    # Windows without it.

    my $appveyor_yml = <<'APPVEYOR_YML';
# {{ $generated }}

skip_tags: true

environment:
  AUTOMATED_TESTING: 1
  TAR_OPTIONS: --warning=no-unknown-keyword

  matrix:
APPVEYOR_YML

    my $appveyor_perl_used = 0;

    if ( $self->appveyor_test_on_cygwin ) {
        $appveyor_perl_used = 1;
        $appveyor_yml .= <<'APPVEYOR_YML';
    - PERL_TYPE: cygwin
      AUTHOR_TESTING: 1

APPVEYOR_YML
    }

    if ( $self->appveyor_test_on_cygwin64 ) {
        $appveyor_perl_used = 1;
        $appveyor_yml .= <<'APPVEYOR_YML';
    - PERL_TYPE: cygwin64
      AUTHOR_TESTING: 1

APPVEYOR_YML
    }

    if ( $self->appveyor_test_on_strawberry ) {

        ## no critic (RegularExpressions::RequireDotMatchAnything)
        ## no critic (RegularExpressions::RequireExtendedFormatting)
        ## no critic (RegularExpressions::RequireLineBoundaryMatching)
        my $auth_regex = join q{|}, map { qr{^\Q$_\E(?:[.].+)?$} } APPVEYOR_AUTHOR_TESTING_PERL();

        for my $strawberry_ref ( $self->_relevant_strawberry_perl_versions_for_appveyor ) {
            $appveyor_perl_used = 1;
            my ( $perl, $url ) = @{$strawberry_ref};

            $appveyor_yml .= <<"APPVEYOR_YML";
    - PERL_TYPE: strawberry
      PERL_VERSION: $perl
APPVEYOR_YML

            if ( $perl =~ $auth_regex ) {
                $appveyor_yml .= "      AUTHOR_TESTING: 1\n";
            }

            $appveyor_yml .= "      STRAWBERRY_URL: $url\n";
            $appveyor_yml .= "\n";
        }
    }

    confess 'No Perl enabled for AppVeyor' if !$appveyor_perl_used;

    $appveyor_yml .= <<'APPVEYOR_YML';
install:
  - ps: 'Write-Host "ERROR: Unknown Perl type ''$env:PERL_TYPE''"'
  - exit 1

for:
APPVEYOR_YML

    if ( $self->appveyor_test_on_cygwin ) {
        $appveyor_yml .= <<'APPVEYOR_YML';
  -
    matrix:
      only:
        - PERL_TYPE: cygwin

    install:
      - c:\cygwin\setup-x86.exe -q -C devel -C perl -P libcrypt-devel -P libssl-devel
      - set PATH=C:\cygwin\bin;C:\cygwin\usr\local\bin;%PATH%

APPVEYOR_YML
    }

    if ( $self->appveyor_test_on_cygwin64 ) {
        $appveyor_yml .= <<'APPVEYOR_YML';
  -
    matrix:
      only:
        - PERL_TYPE: cygwin64

    install:
      - c:\cygwin64\setup-x86_64.exe -q -C devel -C perl -P libcrypt-devel -P libssl-devel
      - set PATH=C:\cygwin64\bin;C:\cygwin64\usr\local\bin;%PATH%

APPVEYOR_YML
    }

    if ( $self->appveyor_test_on_strawberry ) {
        $appveyor_yml .= <<'APPVEYOR_YML';
  -
    matrix:
      only:
        - PERL_TYPE: strawberry

    install:
      - ps: Invoke-WebRequest $env:STRAWBERRY_URL -OutFile strawberry.zip
      - ps: Expand-Archive strawberry.zip -DestinationPath c:\Strawberry
      - if exist c:\Strawberry\relocation.pl.bat c:\Strawberry\relocation.pl.bat
      - erase strawberry.zip
      - set PATH=C:\Strawberry\perl\site\bin;C:\Strawberry\perl\bin;C:\Strawberry\c\bin;%PATH%

APPVEYOR_YML
    }

    $appveyor_yml .= <<'APPVEYOR_YML';
before_build:
  - mv c:\mingw-w64 c:\mingw-w64.old
  - mv c:\mingw c:\mingw.old
  - ps: systeminfo | Select-String "^OS Name", "^OS Version"
  - where perl
  - perl -V
  - ps: Invoke-WebRequest https://raw.githubusercontent.com/skirmess/dzil-inc/master/bin/check-ci-perl-version -OutFile check-ci-perl-version.pl
  - perl check-ci-perl-version.pl --appveyor
  - erase check-ci-perl-version.pl
  - ps: $env:make = perl -MConfig -e'print $Config{make}'
  - echo %make%
  - if not exist %make% where %make%
  - where gcc
  - gcc --version
  - where g++
  - g++ --version
  - ps: Invoke-WebRequest https://cpanmin.us/ -OutFile cpanm.pl
  - perl cpanm.pl App::cpanminus
  - erase cpanm.pl
  - where cpanm
  - perl -S cpanm --version
  - mkdir C:\tmp
  - if     defined AUTHOR_TESTING perl -S cpanm --verbose --installdeps --notest --with-develop .
  - if not defined AUTHOR_TESTING perl -S cpanm --verbose --installdeps --notest .
  - perl -S cpanm --verbose --notest App::ReportPrereqs
  - if     defined AUTHOR_TESTING perl -S report-prereqs --with-develop
  - if not defined AUTHOR_TESTING perl -S report-prereqs

build_script:
  - set PERL_USE_UNSAFE_INC=0
APPVEYOR_YML

    if ( $self->makefile_pl_exists() ) {
        $appveyor_yml .= <<'APPVEYOR_YML';
  - perl Makefile.PL
  - '%make%'
APPVEYOR_YML
    }

    $appveyor_yml .= <<'APPVEYOR_YML';

test_script:
APPVEYOR_YML

    $appveyor_yml .= $self->makefile_pl_exists()
      ? <<'APPVEYOR_YML'
  - '%make% test'
APPVEYOR_YML
      : <<'APPVEYOR_YML';
  - prove -lr t
APPVEYOR_YML

    $appveyor_yml .= <<'APPVEYOR_YML';
  - if defined AUTHOR_TESTING perl -S prove -lr xt/author
APPVEYOR_YML

    $file->spew( $self->fill_in_string($appveyor_yml) );

    return;
}

sub _create_travis_ci_config {
    my ($self) = @_;

    my $file = path('repos')->child( $self->repo_dir )->child(TRAVIS_CI_CONFIG_FILE);
    say " ==> Creating file $file (Travis CI config file)";

    my $travis_yml = <<'TRAVIS_YML';
# {{ $generated }}

language: perl

cache:
  directories:
    - ~/perl5

env:
  global:
    - AUTOMATED_TESTING=1
    - TAR_OPTIONS=--warning=no-unknown-keyword

git:
  submodules: false

matrix:
  include:
TRAVIS_YML

    my %auth;
    @auth{ TRAVIS_CI_AUTHOR_TESTING_PERL() } = ();

    my %osx_perl;
    @osx_perl{ TRAVIS_CI_OSX_PERL() } = ();

    my $perl_helper_used = 0;

  PERL:
    for my $perl ( $self->_relevant_perl_versions_for_travis_ci ) {
        my @os = (undef);
        if ( exists $osx_perl{$perl} ) {
            push @os, 'osx';
        }

        for my $os (@os) {
            $travis_yml .= "    - perl: '$perl'\n";

            # Ubuntu 16.04 (xenial) does not have Perl <= 5.20 images
            my $dist = 'xenial';

            if ( $perl =~ m{ ^ 5 [.] ( [1-9][0-9]* ) $ }xsm ) {
                if ( $1 <= 20 ) {

                    # Ubuntu 14.04 (trusty) has all Perl versions
                    $dist = 'trusty';
                }
            }

            if ( $perl =~ m{ ^ 5 [.] ( [1-9][0-9]* ) [.] ( [0-9]+ ) $ }xsm ) {
                $perl_helper_used = 1;
            }

            my @env;
            if ( ( exists $auth{$perl} ) or ( defined $os ) ) {
                push @env, 'AUTHOR_TESTING=1';
            }

            if (@env) {
                $travis_yml .= '      env: ' . join( q{ }, @env ) . "\n";
            }

            if ( defined $os ) {
                $travis_yml .= "      os: $os\n";
                $dist = undef;
            }

            if ( defined $dist ) {
                $travis_yml .= "      dist: '$dist'\n";
            }

            $travis_yml .= "\n";
        }
    }

    $travis_yml .= <<'TRAVIS_YML';
before_install:
  - |
    case "${TRAVIS_OS_NAME}" in
      "linux" )
        ;;
      "osx"   )
        # TravisCI extracts the broken perl archive with sudo which creates the
        # $HOME/perl5 directory with owner root:staff. Subdirectories under
        # perl5 are owned by user travis.
        sudo chown "$USER" "$HOME/perl5"

        # The perl distribution TravisCI extracts on OSX is incomplete
        sudo rm -rf "$HOME/perl5/perlbrew"

        # Install cpanm and local::lib
        curl -L https://cpanmin.us | perl - App::cpanminus local::lib
        eval $(perl -I $HOME/perl5/lib/perl5/ -Mlocal::lib)
        ;;
    esac
TRAVIS_YML

    if ($perl_helper_used) {
        $travis_yml .= <<'TRAVIS_YML';
  - |
    if [[ $TRAVIS_PERL_VERSION =~ 5[.][1-9][0-9]*[.][0-9][0-9]* ]]
    then
        echo "Initializing the Travis Perl Helper"

        if [ -z "$AUTHOR_TESTING" ]
        then
            AUTHOR_TESTING=0
        fi

        git clone git://github.com/travis-perl/helpers ~/travis-perl-helpers
        source ~/travis-perl-helpers/init
        build-perl

        if [ "$AUTHOR_TESTING" = 0 ]
        then
            unset AUTHOR_TESTING
        fi
    fi
TRAVIS_YML

    }

    $travis_yml .= <<'TRAVIS_YML';
  - which perl
  - perl -V
  - curl -L https://raw.githubusercontent.com/skirmess/dzil-inc/master/bin/check-ci-perl-version | perl - --travis
  - which make
  - which gcc
  - gcc --version
  - which cpanm
  - cpanm --version

install:
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
        cpanm --verbose --installdeps --notest --with-develop .
    else
        cpanm --verbose --installdeps --notest .
    fi
  - cpanm --verbose --notest App::ReportPrereqs
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
        report-prereqs --with-develop
    else
        report-prereqs
    fi

script:
  - PERL_USE_UNSAFE_INC=0
TRAVIS_YML

    $travis_yml .=
      $self->makefile_pl_exists()
      ? "  - perl Makefile.PL && make test\n"
      : "  - prove -lr t\n";

    $travis_yml .= <<'TRAVIS_YML';
  - |
    if [ -n "$AUTHOR_TESTING" ]
    then
        prove -lr xt/author
    fi
TRAVIS_YML

    $file->spew( $self->fill_in_string($travis_yml) );

    return;
}

sub _relevant_perl_5_8_versions_for_travis_ci {
    my ($self) = @_;

    my $earliest_perl = $self->ci_earliest_perl;
    return if version->parse("v$earliest_perl") >= version->parse('v5.9');

    confess 'Perl 5.8.0 is not supported because cpanm does not work on 5.8.0' if $earliest_perl eq '5.8.0';
    confess "Perl $earliest_perl does not exist" if version->parse("v$earliest_perl") > version->parse('v5.8.9');

    return qw(5.8.1 5.8.2 5.8) if $earliest_perl eq '5.8' || $earliest_perl eq '5.8.1';
    return $earliest_perl, '5.8' if version->parse("v$earliest_perl") < version->parse('v5.8.8');

    return $earliest_perl;
}

sub _relevant_perl_5_10_versions_for_travis_ci {
    my ($self) = @_;

    my $earliest_perl = $self->ci_earliest_perl;
    return if version->parse("v$earliest_perl") >= version->parse('v5.11');

    confess "Perl $earliest_perl does not exist" if version->parse("v$earliest_perl") > version->parse('v5.10.1');

    return '5.10' if $earliest_perl eq '5.10.1';
    return qw(5.10.0 5.10);
}

# This generates a list of Perl versions I think are relevant to be tested on
# Travis CI. The list includes all stable versions of Perl, starting with
# 5.8, as major.minor entry. Additionally, the following versions are added:
#  - 5.8.0
#  - 5.8.1
#  - 5.8.2
#  - 5.10.0
sub _relevant_perl_versions_for_travis_ci {
    my ($self) = @_;

    my $earliest_perl = $self->ci_earliest_perl;

    # Generate the list of all stable versions of perl as major.minor,
    # starting with 5.12 (or the first version we are interested in).
    my %perl;
  PERL:
    for my $perl ( perl_versions() ) {
        next PERL if $perl !~ m { ^ 5 [.] ( [1-9][0-9]* ) [.] [0-9]+ $ }xsm;
        my $minor = $1;    ## no critic (RegularExpressions::ProhibitCaptureWithoutTest)

        # Remove dev releases
        next PERL if $minor % 2;

        next PERL if version->parse("v5.$minor") < version->parse("v$earliest_perl");
        next PERL if $minor < 12;

        # Allow us to skip the latest Perl if Travis hasn't it available yet
        if ( exists $ENV{TRAVIS_CI_LATEST_PERL} ) {
            if ( version->parse("v5.$minor") > version->parse("v$ENV{TRAVIS_CI_LATEST_PERL}") ) {
                $self->log("Skipping Perl 5.$minor on Travis");
                next PERL;
            }
        }

        $perl{$minor} = 1;
    }

    my @perls;

    if ( version->parse("v$earliest_perl") < version->parse('v5.11') ) {
        if ( version->parse("v$earliest_perl") < version->parse('v5.9') ) {
            @perls = $self->_relevant_perl_5_8_versions_for_travis_ci;
        }

        push @perls, $self->_relevant_perl_5_10_versions_for_travis_ci;
    }
    elsif ( $earliest_perl =~ m{ ^ 5 [.] ( [1-9][0-9]* ) [.] ( [0-9]+ ) $ }xsm ) {

        # if the earliest perl version has a patch level, add this version to
        # the versions to be tested but skip the major.minor from Travis for
        # this release. The _relevant_perl_5_8_versions_for_travis_ci and
        # _relevant_perl_5_10_versions_for_travis_ci method already does that
        # for these releases.

        @perls = "5.$1.$2";
    }

    # Add the releases >= 5.12 releases
    push @perls, map { "5.$_" } sort { $a <=> $b } keys %perl;

    return @perls;
}

sub _relevant_strawberry_perl_versions_for_appveyor_sort {
    my $x = version->parse("v$a->[2]") <=> version->parse("v$b->[2]");
    return $x if $x;

    if ( $a->[4] ne $b->[4] ) {
        return 1 if $a->[4] eq '64bit';
        return -1;
    }

    return $a->[5] <=> $b->[5];
}

sub _relevant_strawberry_perl_versions_for_appveyor {
    my ($self) = @_;

    my $earliest_perl = version->parse( 'v' . $self->appveyor_earliest_perl );
    my @strawberry_releases =
      reverse
      sort _relevant_strawberry_perl_versions_for_appveyor_sort grep { version->parse("v$_->[1]") >= $earliest_perl } @{ Local::Strawberry->instance->releases };

    my @strawberry_releases_to_use;
    my %perl_configured;
  RELEASE:
    for my $strawberry_ref (@strawberry_releases) {
        if ( $strawberry_ref->[0] eq '5.10' ) {
            next RELEASE if exists $perl_configured{ $strawberry_ref->[1] };
            $perl_configured{ $strawberry_ref->[1] } = 1;
        }
        else {
            next RELEASE if exists $perl_configured{ $strawberry_ref->[0] };
            $perl_configured{ $strawberry_ref->[0] } = 1;
        }
        push @strawberry_releases_to_use, $strawberry_ref;
    }

    return reverse map { [ $_->[1], $_->[3] ] } @strawberry_releases_to_use;
}

sub update_project {
    my ($self) = @_;

    say '===> ', $self->repo;

    $self->_clone_or_update_project;
    $self->_create_appveyor_config;
    $self->_create_travis_ci_config;
    $self->_copy_files_from_submodule_to_project;

    return;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
