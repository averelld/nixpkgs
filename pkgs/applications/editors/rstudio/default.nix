{ stdenv, fetchurl, fetchFromGitHub, makeDesktopItem, cmake, boost
, zlib, openssl, R, qtbase, qtdeclarative, qtsensors, qtwebengine, qtwebchannel
, libuuid, hunspellDicts, unzip, ant, jdk, gnumake, makeWrapper, pandoc
}:

let
  verMajor = "1";
  verMinor = "2";
  verPatch = "679";
  version = "${verMajor}.${verMinor}.${verPatch}";
  ginVer = "2.1.2";
  gwtVer = "2.8.1";
in
stdenv.mkDerivation rec {
  name = "RStudio-${version}";

  nativeBuildInputs = [ cmake unzip ant jdk makeWrapper pandoc ];

  buildInputs = [ boost zlib openssl R qtbase qtdeclarative qtsensors
                  qtwebengine qtwebchannel libuuid ];

  src = fetchFromGitHub {
    owner = "rstudio";
    repo = "rstudio";
    rev = "v${version}";
    sha256 = "156b4vgc85b5m7vfkv0k6is9ay7jxdm8zpmv8md98s47nd5ivbrg";
  };

  # Hack RStudio to only use the input R.
  patches = [ ./r-location.patch ./fix-cmake.patch ];
  postPatch = "substituteInPlace src/cpp/core/r_util/REnvironmentPosix.cpp --replace '@R@' ${R}";

  ginSrc = fetchurl {
    url = "https://s3.amazonaws.com/rstudio-buildtools/gin-${ginVer}.zip";
    sha256 = "16jzmljravpz6p2rxa87k5f7ir8vs7ya75lnfybfajzmci0p13mr";
  };

  gwtSrc = fetchurl {
    url = "https://s3.amazonaws.com/rstudio-buildtools/gwt-${gwtVer}.zip";
    sha256 = "19x000m3jwnkqgi6ic81lkzyjvvxcfacw2j0vcfcaknvvagzhyhb";
  };

  hunspellDictionaries = with stdenv.lib; filter isDerivation (attrValues hunspellDicts);

  mathJaxSrc = fetchurl {
    url = https://s3.amazonaws.com/rstudio-buildtools/mathjax-26.zip;
    sha256 = "0wbcqb9rbfqqvvhqr1pbqax75wp8ydqdyhp91fbqfqp26xzjv6lk";
  };

  rstudiolibclang = fetchurl {
    url = https://s3.amazonaws.com/rstudio-buildtools/libclang-3.5.zip;
    sha256 = "1sl5vb8misipwbbbykdymw172w9qrh8xv3p29g0bf3nzbnv6zc7c";
  };

  rstudiolibclangheaders = fetchurl {
    url = https://s3.amazonaws.com/rstudio-buildtools/libclang-builtin-headers.zip;
    sha256 = "0x4ax186bm3kf098izwmsplckgx1kqzg9iiyzg95rpbqsb4593qb";
  };

  plumberSrc = fetchFromGitHub {
    owner = "trestletech";
    repo = "plumber";
    rev = "v0.4.6";
    sha256 = "02jblwyirgmwz9sdn5w45za35zby2c2l8dvxpwcqz08sv9rg90mm";
  };

  preConfigure =
    ''
      export RSTUDIO_VERSION_MAJOR=${verMajor}
      export RSTUDIO_VERSION_MINOR=${verMinor}
      export RSTUDIO_VERSION_PATCH=${verPatch}

      GWT_LIB_DIR=src/gwt/lib

      mkdir -p $GWT_LIB_DIR/gin/${ginVer}
      unzip ${ginSrc} -d $GWT_LIB_DIR/gin/${ginVer}

      unzip ${gwtSrc}
      mkdir -p $GWT_LIB_DIR/gwt
      mv gwt-${gwtVer} $GWT_LIB_DIR/gwt/${gwtVer}

      mkdir dependencies/common/dictionaries
      for dict in ${builtins.concatStringsSep " " hunspellDictionaries}; do
        for i in "$dict/share/hunspell/"*; do
          ln -sv $i dependencies/common/dictionaries/
        done
      done

      unzip ${mathJaxSrc} -d dependencies/common/mathjax-26
      mkdir -p dependencies/common/libclang/3.5
      unzip ${rstudiolibclang} -d dependencies/common/libclang/3.5
      mkdir -p dependencies/common/libclang/builtin-headers
      unzip ${rstudiolibclangheaders} -d dependencies/common/libclang/builtin-headers

      mkdir -p dependencies/common/pandoc
      cp ${pandoc}/bin/pandoc dependencies/common/pandoc/

      cp -r ${plumberSrc} dependencies/common/plumber
      pushd dependencies/common
      ${R}/bin/R CMD build --no-build-vignettes plumber
      popd
    '';

  enableParallelBuilding = true;

  cmakeFlags = [ "-DRSTUDIO_TARGET=Desktop" "-DQT_QMAKE_EXECUTABLE=$NIX_QT5_TMP/bin/qmake" ];

  desktopItem = makeDesktopItem {
    name = name;
    exec = "rstudio %F";
    icon = "rstudio";
    desktopName = "RStudio";
    genericName = "IDE";
    comment = meta.description;
    categories = "Development;";
    mimeType = "text/x-r-source;text/x-r;text/x-R;text/x-r-doc;text/x-r-sweave;text/x-r-markdown;text/x-r-html;text/x-r-presentation;application/x-r-data;application/x-r-project;text/x-r-history;text/x-r-profile;text/x-tex;text/x-markdown;text/html;text/css;text/javascript;text/x-chdr;text/x-csrc;text/x-c++hdr;text/x-c++src;";
  };

  postInstall = ''
      wrapProgram $out/bin/rstudio --suffix PATH : ${gnumake}/bin
      mkdir $out/share
      cp -r ${desktopItem}/share/applications $out/share
      mkdir $out/share/icons
      ln $out/rstudio.png $out/share/icons
  '';

  meta = with stdenv.lib;
    { description = "Set of integrated tools for the R language";
      homepage = https://www.rstudio.com/;
      license = licenses.agpl3;
      maintainers = with maintainers; [ ehmry changlinli ciil ];
      platforms = platforms.linux;
    };
}
