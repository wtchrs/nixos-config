{
  # spawn-at-startup repeats, so each node goes in its own _children entry.
  wayland.windowManager.niri.settings._children = [
    { spawn-at-startup = [ "niri-float-sticky-launcher" ]; }
    { spawn-at-startup = [ "vesktop" ]; }
    {
      # The spotify wrapper only unsets DISPLAY under NIXOS_OZONE_WL; it does not select Wayland.
      spawn-at-startup = [
        "spotify"
        "--ozone-platform=wayland"
      ];
    }
  ];
}
