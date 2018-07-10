{ stdenv, fetchurl, python3Packages }:

python3Packages.buildPythonApplication rec {
  name = "pyhoca-cli-${version}";
  version = "0.6.0.1";

  src = fetchurl {
    url = "http://code.x2go.org/releases/source/pyhoca-cli/${name}.tar.gz";
    sha256 = "0xfqzmmfawcfc0zjna99ywfa2bdqf97sb8bfgqbzfd2gzq8ygm4a";
  };

  patches = [ ./fix-resume.patch ];

  postPatch = ''
    patchShebangs pyhoca-cli
  '';

  propagatedBuildInputs = with python3Packages; [ setproctitle x2go ];

  preInstall = ''
     mkdir -p $out/bin
     cp pyhoca-cli $out/bin/pyhoca-cli
     chmod +x $out/bin/pyhoca-cli
  '';

  meta = with stdenv.lib; {
    description = "Python x2go client (CLI)";
    homepage = http://x2go.org/;
    license = licenses.gpl2;
    platforms = platforms.linux;
  };
}
