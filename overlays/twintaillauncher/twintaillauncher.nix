{
  buildFHSEnv,
  twintaillauncher-unwrapped,
}:

buildFHSEnv {
  pname = "twintaillauncher";
  inherit (twintaillauncher-unwrapped) version meta;

  targetPkgs =
    pkgs:
    [
      twintaillauncher-unwrapped
    ]
    ++ (with pkgs; [
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

  multiPkgs =
    pkgs: with pkgs; [
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
    ln -s ${twintaillauncher-unwrapped}/share $out/share
  '';
}
