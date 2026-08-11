{ pkgs, ... }:

{
  imports = [
    ./input.nix
  ];

  home.packages = with pkgs; [
    gnome-extension-manager
    gnomeExtensions.blur-my-shell
  ];

  dconf.settings."org/gnome/shell" = {
    disable-user-extensions = false;
    enabled-extensions = [
      pkgs.gnomeExtensions.blur-my-shell.extensionUuid
    ];
  };
}
