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
    ltrace
    lsof
    pciutils
    usbutils
  ];

  xdg.configFile = {
    "catnap/config.toml".source = "${pkgs.catnap}/share/catnap/config.toml";
    "catnap/distros.toml".source = "${pkgs.catnap}/share/catnap/distros.toml";
  };
}
