{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    distro-grub-themes = {
      url = "github:AdisonCavani/distro-grub-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
      # Use `wip/branch` branch for blur feature
      inputs.niri-unstable.url = "git+https://github.com/niri-wm/niri.git?ref=wip/branch";
    };

    quickshell = {
      url = "git+https://git.outfoxxed.me/outfoxxed/quickshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neovim-flake = {
      url = "github:wtchrs/neovim-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:youwen5/zen-browser-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    # Binary cache for cachyos kernel
    extra-substituters = [ "https://cache.garnix.io" ];
    extra-trusted-public-keys = [ "cache.garnix.io:CTFPyKSLcx5RMJKfLo5EEPUObbA78b0YQ2DTCJXqr9g=" ];
  };

  outputs =
    inputs@{ nixpkgs, ... }:
    let
      inherit (nixpkgs.lib)
        mapAttrs
        mapAttrs'
        nameValuePair
        flip
        ;

      hosts = import ./hosts.nix;

      mkHost = import ./lib/mkHost.nix inputs;
      mkHome = import ./lib/mkHome.nix inputs;

      nixosConfigurations = mapAttrs mkHost hosts.system;
      homeConfigurations = flip mapAttrs' hosts.home (
        name: target:
        let
          profileName = target.profileName or "${target.user}@${target.hostName or name}";
        in
        nameValuePair profileName (mkHome name target)
      );

      flakeChecks = import ./lib/flake/checks.nix {
        inherit
          nixpkgs
          hosts
          nixosConfigurations
          homeConfigurations
          ;
      };
      devShells = import ./lib/flake/devShells.nix {
        inherit nixpkgs;
        hosts = hosts.system;
      };
    in
    {
      inherit nixosConfigurations homeConfigurations devShells;
      inherit (flakeChecks) formatter checks;
    };
}
