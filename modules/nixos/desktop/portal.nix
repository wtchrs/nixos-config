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
      # programs.niri sets the same preferences for niri, as upstream niri does.
      # The gnome portal needs GNOME Shell for Access and Notification, so gtk handles them.
      labwc = {
        default = [
          "gnome"
          "gtk"
        ];
        "org.freedesktop.impl.portal.Access" = "gtk";
        "org.freedesktop.impl.portal.Notification" = "gtk";
        "org.freedesktop.impl.portal.Secret" = "gnome-keyring";
      };

      common.default = "*";
    };
  };
}
