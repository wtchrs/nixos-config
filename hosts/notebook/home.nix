_:

{
  # Host-specific Home overrides for this machine's display and wallpaper.
  services.hyprpaper = {
    enable = true;
    settings = {
      splash = false;
      preload = [ "~/Pictures/wallpapers/wallpaper.jpg" ];
      wallpaper = [ ",~/Pictures/wallpapers/wallpaper.jpg" ];
    };
  };

  wayland.windowManager.hyprland.settings.monitor = [
    ",1920x1080,auto,1.2"
  ];
}
