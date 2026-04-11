inputs@{ nixpkgs, home-manager, ... }:

name: host:

let
  inherit (nixpkgs) lib;

  username = host.user;
  hostName = host.hostName or name;

  mkHomeModules = import ./mkHomeModules.nix inputs;

  hostDir = ../hosts/${name};
  # remove metadata
  hostConfig = removeAttrs host [
    "system"
    "user"
    "hostName"
    "homeDirectory"
    "stateVersion"
    "profileName"
  ];
in

nixpkgs.lib.nixosSystem rec {
  inherit (host) system;

  specialArgs = {
    inherit inputs username hostName;
  };

  modules = [
    (import ../overlays inputs)
    inputs.distro-grub-themes.nixosModules.${system}.default
    ../modules
    ../users/${username}/system.nix
    home-manager.nixosModules.home-manager

    (_: {
      nixpkgs.config.allowUnfree = true;
      networking.hostName = lib.mkDefault hostName;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs username hostName; };
        users.${username}.imports = mkHomeModules name host;
      };
    })

    hostDir # `hosts/<name>/default.nix` entry
    hostConfig # inject feature flags
  ];
}
