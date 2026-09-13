{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "niri-float-sticky-launcher" ]; }
    { argv = [ "vesktop" ]; }
    {
      argv = [
        "env"
        "NIXOS_OZONE_WL=1"
        "spotify"
        "--ozone-platform=wayland"
      ];
    }
  ];
}
