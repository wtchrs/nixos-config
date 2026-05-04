{
  lib,
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./display-manager.nix
    ./file-manager.nix
    ./flatpak.nix
  ];

  config = lib.mkIf config.my.features.desktop.enable {
    environment.systemPackages = with pkgs; [
      glib.bin
    ];

    boot.loader.grub2-theme = {
      enable = true;
      theme = "stylish";
      footer = true;
      customResolution = "1920x1080";
    };

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
