{ stdenv, buildPythonApplication, fetchFromGitHub, mpv, requests }:

buildPythonApplication rec {
  pname = "plex-mpv-shim";
  version = "0.2";

  src = fetchFromGitHub {
    owner = "iwalton3";
    repo = pname;
    rev = "c993d5de5d1c54bf061d47ec3e3886ebf9db54f3";
    sha256 = "1yz8132mnvpsmdldakkd2bgzbqvwk0xhsa9djj3399xkc8lki9g6";
  };

  propagatedBuildInputs = [ mpv requests ];

  meta = with stdenv.lib; {
    homepage = "https://github.com/iwalton3/plex-mpv-shim";
    description = "Allows casting of videos to MPV via the Plex mobile and web app.";
    license = licenses.mit;
    platforms = platforms.linux ++ platforms.darwin;
  };
}
