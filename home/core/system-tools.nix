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
    fastfetch
    strace
    ltrace
    lsof
    pciutils
    usbutils
  ];
}
