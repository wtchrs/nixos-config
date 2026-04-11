{ nixpkgs, ... }:

name: target:
let
  inherit (nixpkgs) lib;
  importDir = import ./importDir.nix { inherit lib; };

  desktopEnabled = target.my.features.desktop.enable or false;

  username = target.user;
  # hostName = target.hostName or name;

  hmConfig = removeAttrs target [
    "system"
    "user"
    "hostName"
    "homeDirectory"
    "stateVersion"
    "profileName"
  ];
in
[
  ../home
  ../users/${username}/home.nix # user-specific overrides
  (_: {
    home = {
      inherit username;
      homeDirectory = target.homeDirectory or "/home/${username}";
      stateVersion = target.stateVersion or "26.05";
    };
  })
  hmConfig
]
++ (lib.optional desktopEnabled ../home/features/desktop.nix)
++ importDir ../hosts/${name}/home # host-specific overrides
