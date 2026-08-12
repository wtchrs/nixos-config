{ pkgs, ... }:

{
  # Keep GTK applications in GNOME and niri independent of Plasma's GTK sync.
  gtk = {
    enable = true;
    iconTheme = {
      name = "Adwaita";
      package = pkgs.adwaita-icon-theme;
    };
  };
}
