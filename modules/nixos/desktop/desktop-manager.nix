{ pkgs, ... }:

{
  services.desktopManager = {
    gnome.enable = true;
    plasma6.enable = true;
  };

  xdg.portal = {
    enable = true;
    wlr.enable = true;
    extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];

    configPackages = with pkgs; [
      gnome-session
      kdePackages.plasma-workspace
    ];

    config = {
      niri = {
        default = [
          "gnome"
          "gtk"
        ];

        "org.freedesktop.impl.portal.ScreenCast" = "wlr";
        "org.freedesktop.impl.portal.Screenshot" = "wlr";
      };

      common.default = "*";
    };
  };
}
