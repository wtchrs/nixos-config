inputs@{ nixpkgs, home-manager, ... }:

name: target:
let
  overlays = import ../overlays inputs;
  pkgs = import nixpkgs {
    inherit (target) system;
    inherit overlays;
    config.allowUnfree = true;
  };

  username = target.user;
  hostName = target.hostName or name;

  mkHomeModules = import ./mkHomeModules.nix inputs;
in
home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = { inherit inputs username hostName; };
  modules = [
    (_: {
      nix.settings.experimental-features = [
        "nix-command"
        "flakes"
      ];
    })
  ]
  ++ mkHomeModules name target;
}
