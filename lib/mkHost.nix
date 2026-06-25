inputs@{ nixpkgs, home-manager, ... }:

name: host:

let
  inherit (nixpkgs) lib;

  username = host.user;
  hostName = host.hostName or name;

  importDir = import ./importDir.nix { inherit lib; };
  mkHomeModules = import ./mkHomeModules.nix inputs;
  overlays = import ../overlays inputs;

  hostDir = ../hosts/${name};
  hostConfig = removeAttrs host [
    "system"
    "user"
    "hostName"
    "homeDirectory"
    "stateVersion"
    "profileName"
  ];

  compatArgs = {
    inherit inputs username hostName;

    # Keep the legacy module arg available during the compatibility migration.
    hostSystem = host.system;
  };

  grubModules = lib.optionals (host.system == "x86_64-linux") [
    inputs.grub2-themes.nixosModules.default
    ../modules/features/desktop/grub-theme.nix
  ];
in

{
  flake ? null,
  ...
}:

{
  imports = [
    ../modules
    ../users/${username}/system.nix
    home-manager.nixosModules.home-manager

    (_: {
      _module.args = compatArgs;

      nixpkgs = {
        hostPlatform = host.system;
        config.allowUnfree = true;
        inherit overlays;
      };
      networking.hostName = lib.mkDefault hostName;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = compatArgs // lib.optionalAttrs (flake != null) { inherit flake; };
        users.${username}.imports = mkHomeModules name host;
      };
    })

    hostDir
    hostConfig
  ]
  ++ grubModules
  ++ importDir ../hosts/${name}/system;
}
