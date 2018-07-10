{ lib, fetchurl, buildPythonPackage, gevent, paramiko, requests, simplejson,
xlib, nx-libs }:

buildPythonPackage rec {
  pname = "python-x2go";
  name = "${pname}-${version}";
  version = "0.6.0.2";

  src = fetchurl {
    url = "https://code.x2go.org/releases/source/python-x2go/${name}.tar.gz";
    sha256 = "021r56xv0iyxhlrh2jib2jsiqwdir2pipcfbk863q3qwkds9m2c3";
  };

  propagatedBuildInputs = [ gevent paramiko requests simplejson xlib ];

  postPatch = ''
    substituteInPlace x2go/backends/proxy/nx3.py \
      --replace "/usr/bin/nxproxy" "${nx-libs}/bin/nxproxy"
  '';

  meta = {
    description = "Python x2go support library";
    homepage = http://x2go.org/;
    license = lib.licenses.gpl2;
  };
}
