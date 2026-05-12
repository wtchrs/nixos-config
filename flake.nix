{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nix-cachyos-kernel.url = "github:xddxdd/nix-cachyos-kernel/release";

    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    grub2-themes = {
      url = "github:vinceliuice/grub2-themes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri = {
      url = "github:sodiboo/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    niri-float-sticky = {
      url = "github:probeldev/niri-float-sticky";
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
