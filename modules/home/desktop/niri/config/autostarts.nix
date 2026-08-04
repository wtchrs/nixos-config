_:

{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "qs" ]; }
    { argv = [ "dunst" ]; }
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
