{
  lib,
  config,
  pkgs,
  username,
  hostSystem,
  ...
}:

{
  imports = [
    ./display-manager.nix
    ./file-manager.nix
    ./flatpak.nix
  ] ++ lib.optional (hostSystem == "x86_64-linux") ./grub-theme.nix;

  config = lib.mkIf config.my.features.desktop.enable {
    environment.systemPackages = with pkgs; [
      glib.bin
    ];

    services = {
      seatd = {
        enable = true;
        user = username;
      };

      tumbler.enable = true;
      upower.enable = true;
      playerctld.enable = true;

      pipewire = {
        enable = true;
        pulse.enable = true;
      };
    };

    security = {
      polkit.enable = true;
      rtkit.enable = true;
    };

    xdg.portal = {
      enable = true;
      wlr.enable = true;
      extraPortals = with pkgs; [ xdg-desktop-portal-gnome ];
      config.common.default = "gnome";
    };
  };
}
