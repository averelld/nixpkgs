{ stdenv
, fetchFromGitHub
, pkgconfig
, glib
, glibc
, systemd
}:

stdenv.mkDerivation rec {
  project = "conmon";
  name = "${project}-${version}";
  version = "2.0.4";

  src = fetchFromGitHub {
    owner = "containers";
    repo = project;
    rev = "v${version}";
    sha256 = "1qma778h5fdvyf53ck8qr606aaf4f8msddb7pv5pgn1bywpcxs38";
  };

  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ glib systemd ] ++
    stdenv.lib.optionals (!stdenv.hostPlatform.isMusl) [ glibc glibc.static ];

  installPhase = "install -Dm755 bin/${project} $out/bin/${project}";

  meta = with stdenv.lib; {
    homepage = https://github.com/containers/conmon;
    description = "An OCI container runtime monitor";
    license = licenses.asl20;
    maintainers = with maintainers; [ vdemeester saschagrunert ];
    platforms = platforms.linux;
  };
}
