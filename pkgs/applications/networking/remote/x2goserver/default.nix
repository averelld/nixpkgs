{ stdenv, lib, fetchurl, makeWrapper, perl, perlPackages, which, nx-libs
, utillinux, coreutils, glibc, gawk, gnused, gnugrep, findutils, xorg
, nettools, iproute, bc, procps, psmisc, lsof, pwgen, openssh, sshfs
}:

let binaryDeps = [
  perl which nx-libs utillinux coreutils glibc.bin gawk gnused gnugrep
  findutils nettools iproute bc procps psmisc lsof pwgen openssh sshfs
  xorg.xauth xorg.xinit xorg.xrandr xorg.xmodmap xorg.xwininfo xorg.fontutil
  xorg.xkbcomp xorg.setxkbmap
]; in
stdenv.mkDerivation rec {
  name = "x2goserver-${version}";
  version = "4.1.0.3";

  src = fetchurl {
    url = "http://code.x2go.org/releases/source/x2goserver/${name}.tar.gz";
    sha256 = "1l6wd708kbipib4ldprfiihqmj4895nifg0bkws4x97majislxk7";
  };

  buildInputs = binaryDeps;

  nativeBuildInputs = [ makeWrapper ];

  patches = [ ./xsession-nixos-support.patch ];

  preConfigure = ''
    patchShebangs .
    perl Makefile.PL
    for i in */Makefile; do
      substituteInPlace "$i" --replace "-o root -g root " ""
    done
    substituteInPlace libx2go-server-db-perl/Makefile --replace "chmod 2755" "chmod 755"
  '';

  makeFlags = [ "PREFIX=/" "NXLIBDIR=${nx-libs}/lib/nx" "PERL=${perl}/bin/perl" "PERL_INSTALLDIRS=vendor" ];

  installFlags = [ "DESTDIR=$(out)" ];

  postInstall = ''
    sed -i '/extension GLX/s/^#//' $out/etc/x2go/x2goagent.options
    substituteInPlace $out/X2Go/Config.pm --replace '/etc/x2go' "$out/etc/x2go"
    substituteInPlace $out/X2Go/Server/DB.pm \
      --replace '$x2go_lib_path/libx2go-server-db-sqlite3-wrapper' \
                '$x2go_lib_path/libx2go-server-db-sqlite3-wrapper.pl'
    ln -sf ${nx-libs}/bin/nxagent $out/bin/x2goagent
    for i in $out/sbin/x2go* $out/lib/x2go/libx2go*pl \
      $(find $out/bin -type f) $(ls $out/lib/x2go/x2go* | grep -v x2gocheckport)
    do
      substituteInPlace $i --replace '/etc/x2go' "$out/etc/x2go"
      wrapProgram $i \
        --prefix PATH : ${lib.makeBinPath binaryDeps} \
        --set PERL5LIB "${with perlPackages; makePerlPath
          [ DBI DBDSQLite FileBaseDir TryTiny CaptureTiny ConfigSimple Switch ]}:$out"
    done
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "Remote desktop application, server component";
    homepage = http://x2go.org/;
    platforms = [ "x86_64-linux" ];
    license = licenses.gpl2;
  };
}
