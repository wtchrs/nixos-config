{ pkgs, ... }:

{
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];

    config = {
      niri.default = [
        "gnome"
        "gtk"
      ];

      common.default = "*";
    };
  };
}
