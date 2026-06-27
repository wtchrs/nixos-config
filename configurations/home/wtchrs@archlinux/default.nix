{ inputs, ... }:

let
  system = "x86_64-linux";
  username = "wtchrs";
  hostName = "archlinux";
  overlays = import ../../../overlays inputs;
  pkgs = import inputs.nixpkgs {
    inherit system overlays;
    config.allowUnfree = true;
  };
in
inputs.home-manager.lib.homeManagerConfiguration {
  inherit pkgs;
  extraSpecialArgs = { inherit inputs username hostName; };
  modules = [
    ../../../home/standalone.nix
    ../../../home/core
    ../../../home/desktop
    ../../../home/gaming
    ../../../home/desktop/gaming.nix
    ../../../home/desktop/nvidia.nix
    ../../../users/${username}/home.nix
    (_: {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    })
    ../../nixos/notebook/home/display-outputs.nix
  ];
}
