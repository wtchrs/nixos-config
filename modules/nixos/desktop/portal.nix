{ pkgs, ... }:

let
  # Same preferences as the niri-portals.conf that upstream niri ships.
  # The gnome portal needs GNOME Shell for Access and Notification, so gtk handles them.
  compositorPortals = {
    default = [
      "gnome"
      "gtk"
    ];
    "org.freedesktop.impl.portal.Access" = "gtk";
    "org.freedesktop.impl.portal.Notification" = "gtk";
    "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
  };
in
{
  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [
      xdg-desktop-portal-gnome
      xdg-desktop-portal-gtk
    ];

    config = {
      niri = compositorPortals;
      labwc = compositorPortals;
      common.default = "*";
    };
  };
}
