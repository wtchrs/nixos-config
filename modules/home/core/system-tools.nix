{ pkgs, ... }:

{
  home.packages = with pkgs; [
    # Disk and filesystem usage
    duf
    dust

    # Process and resource monitors
    htop
    iotop
    iftop
    sysstat
    lm_sensors

    # System inspection and tracing
    catnap
    fastfetch
    strace
    # TODO: Remove once nixpkgs includes the upstream fix and tests pass without this override.
    (ltrace.overrideAttrs (old: {
      postPatch = (old.postPatch or "") + ''
        substituteInPlace testsuite/ltrace.minor/demangle.exp \
          --replace-fail \
            '[list debug c++]' \
            '[list debug c++ additional_flags=-std=gnu++17]'
      '';
    }))
    lsof
    pciutils
    usbutils
  ];

  xdg.configFile = {
    "catnap/config.toml".source = "${pkgs.catnap}/share/catnap/config.toml";
    "catnap/distros.toml".source = "${pkgs.catnap}/share/catnap/distros.toml";
  };
}
