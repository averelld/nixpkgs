{ stdenv, fetchurl, autoconf, automake, pkgconfig, which, imake, gccmakedep,
  libtool, libjpeg_turbo, libpng, libxml2, zlib, pixman, xorg }:

stdenv.mkDerivation rec {
  name = "nxagent-${version}";
  version = "3.5.99.20-1";

  src = fetchurl {
    url = "http://code.x2go.org/releases/source/nx-libs/nx-libs-${version}-full.tar.gz";
    sha256 = "05g18mh11111pxcjakfn339xfgw225kqnni379dvggnl0i9aba66";
  };

  buildInputs = [
    autoconf automake pkgconfig which imake gccmakedep libtool
    xorg.libX11 xorg.libXcomposite xorg.libXdamage xorg.libXdmcp xorg.libXext
    xorg.libXfixes xorg.libXinerama xorg.libXpm xorg.libXrandr xorg.libXtst
    xorg.xorgproto xorg.xkeyboardconfig xorg.xkbcomp
    xorg.libXfont2 libjpeg_turbo libpng libxml2 zlib pixman
  ];

  postPatch = ''
    patchShebangs .
  '';

  makeFlags = [ "DESTDIR=\${out}" "PREFIX=" ];

  installFlags = [ "DESTDIR=$(out)" "/bin" ];

  postInstall = ''
    #ln -sf $out/bin/nxagent $out/lib/nx/bin/nxagent
  '';

  enableParallelBuilding = true;

  meta = with stdenv.lib; {
    description = "NX Agent";
    homepage = http://x2go.org/;
    platforms = [ "x86_64-linux" ];
    license = licenses.gpl2;
  };
}
