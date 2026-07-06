{ pkgs, ... }:

{
  imports = [
    ./input.nix
  ];

  dconf.settings."org/gnome/shell" = {
    disable-user-extensions = false;
    enabled-extensions = [
      pkgs.gnomeExtensions.blur-my-shell.extensionUuid
    ];
  };
}
