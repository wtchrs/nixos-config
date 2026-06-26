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
    ../../../home/standalone-linux.nix
    ../../../home
    ../../../users/${username}/home.nix
    (_: {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    })
    {
      my.features = {
        desktop.enable = true;
        nvidia.enable = true;
        gaming.enable = true;
      };
    }
    ../../nixos/notebook/home/display-outputs.nix
  ];
}
