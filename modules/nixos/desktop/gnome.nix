{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    gnomeExtensions.blur-my-shell
    gnome-extension-manager
  ];

  services.desktopManager.gnome.enable = true;
}
