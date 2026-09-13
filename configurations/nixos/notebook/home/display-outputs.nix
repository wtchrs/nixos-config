_:

{
  wayland.windowManager.hyprland.settings.monitor = [
    "eDP-1,1920x1080@60.008,1280x0,1.25"
  ];

  # Display settings for niri
  programs.niri.settings.outputs = {
    "eDP-1" = {
      mode = {
        width = 1920;
        height = 1080;
        refresh = 60.008;
      };

      scale = 1.25;

      position = {
        x = 1280;
        y = 0;
      };

      transform = {
        rotation = 0;
        flipped = false;
      };
    };
  };
}
