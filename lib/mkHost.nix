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

nixpkgs.lib.nixosSystem {
  inherit (host) system;

  specialArgs = {
    inherit inputs username hostName;

    # Expose the host platform as pre-module metadata for platform-gated imports.
    # Do not derive this from `pkgs` or `config` inside `imports`, as that can
    # recurse during module collection.
    hostSystem = host.system;
  };

  modules = [
    ../modules
    ../users/${username}/system.nix
    home-manager.nixosModules.home-manager

    (_: {
      nixpkgs.config.allowUnfree = true;
      networking.hostName = lib.mkDefault hostName;
      nixpkgs.overlays = overlays;

      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = { inherit inputs username hostName; };
        users.${username}.imports = mkHomeModules name host;
      };
    })

    hostDir # `hosts/<name>/default.nix` entry
    hostConfig # inject feature flags
  ]
  # `grub2-themes` flake provides only `x86_64-linux` derivation
  ++ lib.optional (host.system == "x86_64-linux") inputs.grub2-themes.nixosModules.default
  ++ importDir ../hosts/${name}/system; # host-specific overrides
}
