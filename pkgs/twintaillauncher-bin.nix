{
  lib,
  buildFHSEnv,
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
  gamescope,

  glib-networking,
  gsettings-desktop-schemas,

  libappindicator-gtk3,
  libayatana-appindicator,
}:

let
  unwrapped = stdenv.mkDerivation rec {
    pname = "twintaillauncher-unwrapped";
    version = "2.0.0";

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
      hash = "sha256-4JWIFaGR2TRsNpYed1QDzgmUUzxOrsrWKw5s6WWb994=";
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
  };
in

buildFHSEnv {
  pname = "twintaillauncher";
  inherit (unwrapped) version meta;

  targetPkgs = pkgs: [
    unwrapped
  ] ++ (with pkgs; [
    bash
    coreutils
    file
    findutils
    gamescope
    gnugrep
    gnused
    gnutar
    gzip
    xz
    unzip
    p7zip
    cabextract
    curl
    wget
    xdg-utils
    zenity
    glibc_multi.bin
    pciutils
    usbutils
  ]);

  multiArch = true;
  includeClosures = true;

  multiPkgs = pkgs: with pkgs; [
    glibc
    libxcrypt
    gcc.cc.lib

    libGL
    vulkan-loader
    libdrm
    libgbm
    udev
    libudev0-shim
    libva

    alsa-lib
    libpulseaudio
    pipewire
  ];

  profile = ''
    export LIBGL_DRIVERS_PATH=/run/opengl-driver/lib/dri:/run/opengl-driver-32/lib/dri
    export __EGL_VENDOR_LIBRARY_DIRS=/run/opengl-driver/share/glvnd/egl_vendor.d:/run/opengl-driver-32/share/glvnd/egl_vendor.d
    export LIBVA_DRIVERS_PATH=/run/opengl-driver/lib/dri:/run/opengl-driver-32/lib/dri
    export VDPAU_DRIVER_PATH=/run/opengl-driver/lib/vdpau:/run/opengl-driver-32/lib/vdpau
  '';

  runScript = "twintaillauncher";

  extraInstallCommands = ''
    ln -s ${unwrapped}/share $out/share
  '';
}
