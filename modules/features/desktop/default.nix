{
  pkgs,
  username,
  ...
}:

{
  imports = [
    ./file-manager.nix
    ./flatpak.nix
    ./keyring.nix
  ];

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
}
