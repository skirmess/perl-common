package Local::Workflow;

use 5.010;
use strict;
use warnings;

our $VERSION = '0.001';

use Moo;

use Carp;

use namespace::autoclean 0.09;

has min_perl_linux => (
    is       => 'ro',
    required => 1,
);

has min_perl_strawberry => (
    is       => 'ro',
    required => 1,
);

sub create {
    my ($self) = @_;

    my @test;
    push @test, $self->matrix();

    for my $type (qw(author linux macos-cellar macos cygwin strawberry wsl1)) {
        push @test, "  $type:";
        push @test, $self->job_name($type);
        push @test, $self->job_runs_on($type);
        push @test, $self->job_needs($type);
        push @test, q{};

        push @test, $self->job_strategy($type);
        push @test, $self->job_matrix($type);
        push @test, q{};

        push @test, $self->job_env($type);
        push @test, q{};

        push @test, $self->job_defaults($type);
        push @test, q{};

        push @test, "    steps:";

        push @test, $self->job_checkout_repo($type);
        push @test, q{};

        push @test, $self->job_actions_setup_perl($type);
        push @test, $self->job_actions_setup_cygwin($type);
        push @test, $self->job_actions_setup_wsl1($type);
        push @test, q{};

        push @test, $self->job_uname($type);
        push @test, $self->job_systeminfo($type);
        push @test, q{};

        push @test, $self->job_find_perl($type);
        push @test, q{};

        push @test, $self->job_perl_version($type);
        push @test, q{};

        push @test, $self->job_check_perl_version($type);
        push @test, q{};

        push @test, $self->job_find_make($type);
        push @test, q{};

        push @test, $self->job_find_home($type);
        push @test, q{};

        push @test, $self->job_gcc( $type, 'gcc' );
        push @test, q{};

        push @test, $self->job_gcc( $type, 'g++' );
        push @test, q{};

        push @test, $self->job_redirect_cpanm_log($type);
        push @test, q{};

        push @test, $self->job_install_cpanm($type);
        push @test, q{};

        push @test, $self->job_installsitebin($type);
        push @test, q{};

        push @test, $self->job_cpanm_version($type);
        push @test, q{};

        push @test, $self->job_cpanm_installdeps($type);
        push @test, q{};

        push @test, $self->job_cpanm_install_reportprereqs($type);
        push @test, q{};

        push @test, $self->job_reportprereqs($type);
        push @test, q{};

        push @test, $self->job_perl_MakefilePL($type);
        push @test, q{};

        push @test, $self->job_make( $type, undef );
        push @test, q{};

        push @test, $self->job_make( $type, 'test' );
        push @test, q{};

        push @test, $self->job_prove_xt($type);
        push @test, q{};

        push @test, $self->job_upload_artifact($type);
        push @test, q{};
    }

    my $output = join "\n", @test, q{};
    $output =~ s{\n\n+}{\n\n}xsmg;

    chomp $output;

    return $output;
}

sub job_actions_setup_cygwin {
    my ( $self, $type ) = @_;

    return if $type ne 'cygwin';

    return <<'EOF';
      - uses: cygwin/cygwin-install-action@master
        with:
          packages: >-
            gcc-core
            gcc-g++
            git
            libcrypt-devel
            libssl-devel
            make
            perl
            wget
          platform: ${{ matrix.platform }}
EOF
}

sub job_actions_setup_perl {
    my ( $self, $type ) = @_;

    return if $type eq 'macos-cellar';
    return if $type eq 'cygwin';
    return if $type eq 'wsl1';

    croak "unknown type $type" if $type ne 'author' && $type ne 'linux' && $type ne 'macos' && $type ne 'strawberry';

    my @result;
    push @result, <<'EOF';
      - uses: shogo82148/actions-setup-perl@v1
        with:
EOF

    if ( $type eq 'author' ) {
        push @result, '          perl-version: latest';
    }
    elsif ( $type eq 'linux' || $type eq 'macos' ) {
        push @result, '          perl-version: ${{ matrix.perl }}';
    }
    elsif ( $type eq 'strawberry' ) {
        push @result, <<'EOF';
          perl-version: ${{ matrix.perl }}
          distribution: strawberry
EOF
    }

    chomp @result;
    return @result;
}

sub job_actions_setup_wsl1 {
    my ( $self, $type ) = @_;

    return if $type ne 'wsl1';

    return <<'EOF';
      - uses: Vampire/setup-wsl@v1
        with:
          distribution: ${{ matrix.distribution }}
          additional-packages: ${{ matrix.packages }}
EOF
}

sub job_check_perl_version {
    my ( $self, $type ) = @_;

    return if $type eq 'author';
    return if $type eq 'macos-cellar';
    return if $type eq 'cygwin';
    return if $type eq 'wsl1';

    croak "unknown type $type" if $type ne 'linux' && $type ne 'macos' && $type ne 'strawberry';

    return <<'EOF';
      - name: check perl version
        run: |
          my $perl = '${{ matrix.perl }}';
          print "Perl (from matrix): $perl\n";
          print "Perl:               $]\n";

          die "Unable to parse Perl version\n" if $perl !~ m{ ^ ( [1-9][0-9]* ) [.] ( [0-9]+ ) [.] ( [0-9]+ ) $ }xsm;
          die "We asked for Perl $perl but got $]\n" if $] ne sprintf '%i.%03i%03i', $1, $2, $3;
          print "Perl $perl is requested and $] is installed. Good!\n";
        shell: perl {0}
EOF
}

sub job_checkout_repo {
    my ( $self, $type ) = @_;

    return <<'EOF';
      - uses: actions/checkout@v2
        with:
          path: ${{ github.event.repository.name }}
EOF
}

sub job_cpanm_installdeps {
    my ( $self, $type ) = @_;

    my @result;

    if ( $type eq 'author' ) {
        push @result, '      - name: cpanm --installdeps --notest --with-develop .';
        push @result, '        run: ${{ steps.perl.outputs.bin }} ${{ steps.installsitebin.outputs.path }}/cpanm --verbose --installdeps --notest --with-develop .';
    }
    else {
        push @result, '      - name: cpanm --installdeps --notest .';
        push @result, '        run: |';
        push @result, '          mv cpanfile .cpanfile.disabled';
        push @result, '          ${{ steps.perl.outputs.bin }} ${{ steps.installsitebin.outputs.path }}' . ( $type eq 'strawberry' ? q{\\} : q{/} ) . 'cpanm --verbose --installdeps --notest .';
        push @result, '          mv .cpanfile.disabled cpanfile';
    }

    push @result, '        working-directory: ${{ github.event.repository.name }}';
    push @result, '        env:';
    push @result, '          AUTOMATED_TESTING: 1';

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    chomp @result;
    return @result;
}

sub job_cpanm_install_reportprereqs {
    my ( $self, $type ) = @_;

    my @result;
    push @result, '      - name: cpanm --notest App::ReportPrereqs';
    push @result, '        run: ${{ steps.perl.outputs.bin }} ${{ steps.installsitebin.outputs.path }}' . ( $type eq 'strawberry' ? q{\\} : q{/} ) . 'cpanm --verbose --notest App::ReportPrereqs';

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    chomp @result;
    return @result;
}

sub job_cpanm_version {
    my ( $self, $type ) = @_;

    my @result;
    push @result, '      - name: cpanm --version';
    push @result, '        run: ${{ steps.perl.outputs.bin }} ${{ steps.installsitebin.outputs.path }}' . ( $type eq 'strawberry' ? q{\\} : q{/} ) . 'cpanm --version';

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    chomp @result;
    return @result;
}

sub job_defaults {
    my ( $self, $type ) = @_;

    return <<'EOF' if $type eq 'cygwin';
    defaults:
      run:
        shell: bash -o igncr {0}
EOF

    return <<'EOF' if $type eq 'wsl1';
    defaults:
      run:
        shell: wsl-bash {0}
EOF

    return;
}

sub job_env {
    my ( $self, $type ) = @_;

    my $result = <<'EOF';
    env:
      TAR_OPTIONS: --warning=no-unknown-keyword
EOF
    if ( $type eq 'wsl1' ) {
        $result .= '      WSLENV: AUTOMATED_TESTING:PERL_USE_UNSAFE_INC:TAR_OPTIONS';
    }

    return $result;
}

sub job_find_perl {
    my ( $self, $type ) = @_;

    my @result;
    push @result, <<'EOF';
      - name: find perl
        run: perl -e 'print qq{perl = $^X\n::set-output name=bin::$^X\n}'
EOF

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    push @result, '        id: perl';

    chomp @result;
    return @result;
}

sub job_find_home {
    my ( $self, $type ) = @_;

    return if $type ne 'strawberry';

    return <<'EOF';
      - name: find home
        run: |
          $homedir = perl -e 'print $ENV{HOME} || eval { require File::HomeDir; File::HomeDir->my_home } || join(q{}, @ENV{qw(HOMEDRIVE HOMEPATH)})'
          echo "home = $homedir"
          echo "::set-output name=path::$homedir"
        id: home
EOF
}

sub job_find_make {
    my ( $self, $type ) = @_;

    my @result;
    push @result, <<'EOF';
      - name: find make
        run: |
EOF

    if ( $type eq 'author' || $type eq 'linux' || $type eq 'macos-cellar' || $type eq 'macos' || $type eq 'cygwin' || $type eq 'wsl1' ) {
        push @result, q{          make=$(which $(${{ steps.perl.outputs.bin }} -MConfig -e 'print $Config{make}'))};
    }
    elsif ( $type eq 'strawberry' ) {
        push @result, <<'EOF';
          $make = ${{ steps.perl.outputs.bin }} -MConfig -e 'print $Config{make}'
          $make = (Get-Command $make | select -first 1).path
EOF
    }
    else {
        croak "unknown type $type";
    }

    push @result, <<'EOF';
          echo "make = $make"
          echo "::set-output name=bin::$make"
EOF

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    push @result, '        id: make';

    chomp @result;
    return @result;
}

sub job_gcc {
    my ( $self, $type, $cmd ) = @_;

    my @result;
    push @result, <<"EOF";
      - name: $cmd --version
        run: |
EOF

    if ( $type eq 'author' || $type eq 'linux' || $type eq 'macos-cellar' || $type eq 'macos' || $type eq 'cygwin' || $type eq 'wsl1' ) {
        push @result, <<"EOF";
          which $cmd
          $cmd --version
EOF

        if ( $type eq 'cygwin' ) {
            push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
        }
    }
    elsif ( $type eq 'strawberry' ) {
        push @result, <<"EOF";
          (Get-Command $cmd | select -first 1).path
          $cmd --version
EOF
    }
    else {
        croak "unknown type $type";
    }

    chomp @result;
    return @result;
}

sub job_install_cpanm {
    my ( $self, $type ) = @_;

    my @result;
    push @result, <<'EOF';
      - name: install cpanm
        run: |
EOF

    if ( $type eq 'strawberry' ) {
        push @result, '          Invoke-WebRequest https://cpanmin.us/ -OutFile cpanm.pl';
    }
    else {
        push @result, '          wget --no-check-certificate -O cpanm.pl https://cpanmin.us/';
    }

    if ( $type eq 'linux' ) {
        push @result, <<'EOF';

          if [[ ${{ matrix.perl }} == 5.10.0 ]]
          then
            ${{ steps.perl.outputs.bin }} cpanm.pl version@0.9912
          fi

EOF
    }

    push @result, '          ${{ steps.perl.outputs.bin }} cpanm.pl --reinstall App::cpanminus';

    if ( $type eq 'strawberry' ) {
        push @result, <<'EOF';
          erase cpanm.pl
EOF
    }
    else {
        push @result, '          rm -f cpanm.pl';

        if ( $type eq 'cygwin' ) {
            push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
        }
    }

    chomp @result;
    return @result;
}

sub job_installsitebin {
    my ( $self, $type ) = @_;

    my @result;
    push @result, <<'EOF';
      - name: installsitebin
        run: |
EOF

    if ( $type eq 'strawberry' ) {
        push @result, q{          $installsitebin = ${{ steps.perl.outputs.bin }} -MConfig -e 'print $Config{installsitebin};'};
    }
    else {
        push @result, q{          installsitebin=$(${{ steps.perl.outputs.bin }} -MConfig -e 'print $Config{installsitebin};')};
    }

    push @result, <<'EOF';
          echo "installsitebin = $installsitebin"
          echo "::set-output name=path::$installsitebin"
EOF

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    push @result, '        id: installsitebin';

    chomp @result;
    return @result;
}

sub job_make {
    my ( $self, $type, $cmd ) = @_;

    my @result;
    push @result, '      - name: make';
    if ( defined $cmd ) {
        $result[-1] .= " $cmd";
    }

    push @result, '        run: ${{ steps.make.outputs.bin }}';
    if ( defined $cmd ) {
        $result[-1] .= " $cmd";
    }

    push @result, <<'EOF';
        working-directory: ${{ github.event.repository.name }}
        env:
EOF

    if ( defined $cmd && $cmd eq 'test' ) {
        push @result, '          AUTOMATED_TESTING: 1';
    }

    if ( $type eq 'cygwin' ) {
        push @result, '          PATH: /usr/local/bin:/usr/bin';
    }

    push @result, '          PERL_USE_UNSAFE_INC: 0';

    chomp @result;
    return @result;
}

sub job_perl_MakefilePL {
    my ( $self, $type ) = @_;

    my @result;
    push @result, <<'EOF';
      - name: perl Makefile.PL
        run: ${{ steps.perl.outputs.bin }} Makefile.PL
        working-directory: ${{ github.event.repository.name }}
        env:
          AUTOMATED_TESTING: 1
EOF

    if ( $type eq 'cygwin' ) {
        push @result, '          PATH: /usr/local/bin:/usr/bin';
    }

    push @result, '          PERL_USE_UNSAFE_INC: 0';

    chomp @result;
    return @result;
}

sub job_perl_version {
    my ( $self, $type ) = @_;

    my @result;

    push @result, <<'EOF';
      - name: perl -V
        run: ${{ steps.perl.outputs.bin }} -V
EOF

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    chomp @result;
    return @result;
}

sub job_prove_xt {
    my ( $self, $type ) = @_;

    return if $type ne 'author';

    return <<'EOF';
      - run: ${{ steps.perl.outputs.bin }} ${{ steps.installsitebin.outputs.path }}/prove -lr xt/author
        working-directory: ${{ github.event.repository.name }}
        env:
          AUTOMATED_TESTING: 1
          PERL_USE_UNSAFE_INC: 0
EOF
}

sub job_matrix {
    my ( $self, $type ) = @_;

    return '      matrix: ${{ fromJson(needs.matrix.outputs.linux) }}'      if $type eq 'linux';
    return '      matrix: ${{ fromJson(needs.matrix.outputs.macos) }}'      if $type eq 'macos';
    return "      matrix:\n        platform: [ 'x86', 'x86_64' ]"           if $type eq 'cygwin';
    return '      matrix: ${{ fromJson(needs.matrix.outputs.strawberry) }}' if $type eq 'strawberry';
    return <<'EOF'                                                          if $type eq 'wsl1';
      matrix:
        include:
          - distribution: 'Debian'
            packages: >-
              g++
              gcc
              git
              libio-socket-ssl-perl
              liblwp-protocol-https-perl
              libnet-ssleay-perl
              libperl-dev
              make
              wget
          - distribution: 'openSUSE-Leap-15.2'
            packages: >-
              gcc
              gcc-c++
              git
              make
              perl-IO-Socket-SSL
              perl-Net-SSLeay
              which
          - distribution: 'Ubuntu-16.04'
            packages: >-
              g++
              gcc
              libio-socket-ssl-perl
              libnet-ssleay-perl
              make
          - distribution: 'Ubuntu-18.04'
            packages: >-
              g++
              gcc
              libio-socket-ssl-perl
              libnet-ssleay-perl
              make
          - distribution: 'Ubuntu-20.04'
            packages: >-
              g++
              gcc
              libio-socket-ssl-perl
              libnet-ssleay-perl
              make
EOF

    return;
}

sub job_name {
    my ( $self, $type ) = @_;

    return "    name: Author Tests"                    if $type eq 'author';
    return '    name: Linux Perl ${{ matrix.perl }}'   if $type eq 'linux';
    return '    name: macOS Cellar'                    if $type eq 'macos-cellar';
    return '    name: macOS Perl ${{ matrix.perl }}'   if $type eq 'macos';
    return '    name: Cygwin ${{ matrix.platform }}'   if $type eq 'cygwin';
    return '    name: Strawberry ${{ matrix.perl }}'   if $type eq 'strawberry';
    return '    name: WSL1 ${{ matrix.distribution }}' if $type eq 'wsl1';

    croak "unknown type $type";
}

sub job_needs {
    my ( $self, $type ) = @_;

    return "    needs: matrix" if $type eq 'linux' || $type eq 'macos' || $type eq 'strawberry';
    return;
}

sub job_redirect_cpanm_log {
    my ( $self, $type ) = @_;

    return if $type ne 'wsl1';

    return <<'EOF';
      - name: redirect cpanm log files
        run: |
          mkdir /mnt/c/Users/runneradmin/.cpanm
          rm -rf ~/.cpanm
          ln -s /mnt/c/Users/runneradmin/.cpanm ~/.cpanm
EOF
}

sub job_reportprereqs {
    my ( $self, $type ) = @_;

    my @result;
    push @result, '      - name: report-prereqs';
    push @result, '        run: ${{ steps.perl.outputs.bin }} ${{ steps.installsitebin.outputs.path }}' . ( $type eq 'strawberry' ? q{\\} : q{/} ) . 'report-prereqs' . ( $type eq 'author' ? ' --with-develop' : q{} );
    push @result, '        working-directory: ${{ github.event.repository.name }}';

    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
        env:
          PATH: /usr/local/bin:/usr/bin
EOF
    }

    chomp @result;
    return @result;
}

sub job_runs_on {
    my ( $self, $type ) = @_;

    return "    runs-on: ubuntu-latest"  if $type eq 'author' || $type eq 'linux';
    return "    runs-on: macos-latest"   if $type eq 'macos'  || $type eq 'macos-cellar';
    return "    runs-on: windows-latest" if $type eq 'cygwin' || $type eq 'strawberry' || $type eq 'wsl1';

    croak "unknown type $type";
}

sub job_strategy {
    my ( $self, $type ) = @_;

    return if $type eq 'author';
    return if $type eq 'macos-cellar';

    my $return = <<'EOF';
    strategy:
      fail-fast: false
EOF
    chomp $return;
    return $return;
}

sub job_systeminfo {
    my ( $self, $type ) = @_;

    return if $type eq 'author';
    return if $type eq 'linux';
    return if $type eq 'macos-cellar';
    return if $type eq 'macos';

    my @result;
    push @result, <<'EOF';
      - name: sysinfo
        run: systeminfo | Select-String "^OS Name", "^OS Version"
EOF

    if ( $type eq 'cygwin' || $type eq 'wsl1' ) {
        push @result, '        shell: powershell';
    }

    chomp @result;
    return @result;
}

sub job_uname {
    my ( $self, $type ) = @_;

    return if $type eq 'cygwin';
    return if $type eq 'strawberry';
    return if $type eq 'wsl1';

    return '      - run: uname -a';
}

sub job_upload_artifact {
    my ( $self, $type ) = @_;

    my @result;
    push @result, <<'EOF';
      - uses: actions/upload-artifact@v2
        with:
EOF
    if ( $type eq 'cygwin' ) {
        push @result, <<'EOF';
          name: cygwin-${{ matrix.platform }}
          path: c:/cygwin/home/runneradmin/.cpanm/work/*/build.log
EOF
    }
    elsif ( $type eq 'strawberry' ) {
        push @result, <<'EOF';
          name: strawberry-perl_${{ matrix.perl }}
          path: ${{ steps.home.outputs.path }}/.cpanm/work/*/build.log
EOF
    }
    else {
        if ( $type eq 'author' ) {
            push @result, '          name: author-tests';
        }
        elsif ( $type eq 'linux' ) {
            push @result, '          name: linux-perl_${{ matrix.perl }}';
        }
        elsif ( $type eq 'macos-cellar' ) {
            push @result, '          name: macos-cellar';
        }
        elsif ( $type eq 'macos' ) {
            push @result, '          name: macos-perl_${{ matrix.perl }}';
        }
        elsif ( $type eq 'wsl1' ) {
            push @result, '          name: wsl1-${{ matrix.distribution }}';
        }
        else {
            croak "unknown type $type";
        }

        push @result, '          path: ~/.cpanm/work/*/build.log';
    }

    push @result, '        if: failure()';

    chomp @result;
    return @result;
}

sub matrix {
    my ($self) = @_;

    my @result;
    push @result, <<'EOF';
name: test

on:
  push:
  pull_request:
  schedule:
    - cron:  '5 7 11 * *'

jobs:
  matrix:
    runs-on: ubuntu-latest
    steps:
      - uses: shogo82148/actions-setup-perl@v1

      - id: linux
        run: |
          use Actions::Core;
          use version 0.77;
EOF

    push @result, q{};
    push @result, q{          my $min_perl = '} . $self->min_perl_linux . q{';};
    push @result, q{};
    push @result, <<'EOF';
          sub perl {
              my @perl =
                grep { version->parse("v$_") >= version->parse('v5.12.0') }
                grep { version->parse("v$_") >= version->parse("v$min_perl") } perl_versions( platform => 'linux' );

              for my $v (qw(5.10.1 5.10.0 5.8.9)) {
                  return @perl if version->parse("v$min_perl") > version->parse("v$v");
                  push @perl, $v;
              }

              return @perl if version->parse("v$min_perl") == version->parse('v5.8.9');
              return @perl, '5.8.2', '5.8.1' if version->parse("v$min_perl") <= version->parse('v5.8.1');
              return @perl, $min_perl;
          }

          set_output( matrix => { perl => [ perl() ] } );
        shell: perl {0}

      - id: macos
        run: |
          use Actions::Core;

          set_output( matrix => { perl => [ ( perl_versions( platform => 'darwin' ) )[0] ] } );
        shell: perl {0}

      - id: strawberry
        run: |
          use Actions::Core;
          use version 0.77;

EOF

    # The non-Strawberry Windows Perl of the Github Action has a lot of
    # problems installing CPAN modules. We don't test with this Perl as we
    # don't want to debug module installation. Testing on Strawberry should be enough

    push @result, q{};
    push @result, q{          my $min_perl = '} . $self->min_perl_strawberry . q{';};
    push @result, q{};

    push @result, <<'EOF';
          sub perl {
              my @perl =
                grep { version->parse("v$_") >= version->parse("v$min_perl") } perl_versions( platform => 'win32', distribution => 'strawberry' );

              return @perl;
          }

          set_output( matrix => { perl => [ perl() ] } );
        shell: perl {0}

    outputs:
      linux: ${{ steps.linux.outputs.matrix }}
      macos: ${{ steps.macos.outputs.matrix }}
      strawberry: ${{ steps.strawberry.outputs.matrix }}
EOF

    push @result, q{};

    chomp @result;
    return @result;
}

1;

# vim: ts=4 sts=4 sw=4 et: syntax=perl
