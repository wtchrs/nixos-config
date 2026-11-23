{
  # spawn-at-startup repeats, so each node goes in its own _children entry.
  wayland.windowManager.niri.settings._children = [
    { spawn-at-startup = [ "niri-float-sticky-launcher" ]; }
    { spawn-at-startup = [ "vesktop" ]; }
    {
      spawn-at-startup = [
        "env"
        "NIXOS_OZONE_WL=1"
        "spotify"
        "--ozone-platform=wayland"
      ];
    }
  ];
}
