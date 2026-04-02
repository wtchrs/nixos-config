{
  description = "NixOS configuration";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-25.05";

    home-manager = {
      url = "github:nix-community/home-manager/release-25.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs@{ nixpkgs, ... }:
    let
      hosts = import ./lib/flake/hosts.nix;
      mkHost = import ./lib/flake/mkHost.nix inputs;
      nixosConfigurations = nixpkgs.lib.mapAttrs mkHost hosts;
      flakeChecks = import ./lib/flake/checks.nix {
        inherit nixpkgs hosts nixosConfigurations;
      };
    in
    {
      inherit nixosConfigurations;
      inherit (flakeChecks) formatter checks;
    };
}
