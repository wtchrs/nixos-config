{
  lib,
  stdenv,
  fetchurl,
  dpkg,
  autoPatchelfHook,
  wrapGAppsHook4,

  cairo,
  gdk-pixbuf,
  glib,
  gtk3,
  pango,
  webkitgtk_4_1,
  libsoup_3,
  librsvg,
  openssl,

  glib-networking,
  gsettings-desktop-schemas,

  libappindicator-gtk3,
  libayatana-appindicator,
}:

stdenv.mkDerivation rec {
  pname = "twintaillauncher-unwrapped";
  version = "2.4.0";

  meta = {
    description = "A multi-platform launcher for anime games";
    homepage = "https://github.com/TwintailTeam/TwintailLauncher";
    license = lib.licenses.gpl3Only;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
    platforms = [ "x86_64-linux" ];
    mainProgram = "twintaillauncher";
  };

  src = fetchurl {
    url = "https://github.com/TwintailTeam/TwintailLauncher/releases/download/ttl-v${version}/twintaillauncher_${version}_amd64.deb";
    hash = "sha256-LxfKIGWeSC8HupM/YvNDkA3foijFeR/q101zafDPjNk=";
  };

  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    dpkg
    autoPatchelfHook
    wrapGAppsHook4
  ];

  buildInputs = [
    cairo
    gdk-pixbuf
    glib
    gtk3
    pango
    webkitgtk_4_1
    libsoup_3
    librsvg
    openssl
    stdenv.cc.cc.lib

    glib-networking
    gsettings-desktop-schemas
  ];

  runtimeDependencies = [
    libayatana-appindicator
    libappindicator-gtk3
  ];

  unpackPhase = ''
    runHook preUnpack
    dpkg-deb -x "$src" .
    runHook postUnpack
  '';

  preFixup = ''
    gappsWrapperArgs+=(
      --prefix GIO_EXTRA_MODULES : ${glib-networking}/lib/gio/modules
    )
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out"
    cp -a usr/* "$out/"

    runHook postInstall
  '';
}
