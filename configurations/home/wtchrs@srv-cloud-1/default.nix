{ inputs, ... }:

let
  system = "aarch64-linux";
  username = "wtchrs";
  hostName = "srv-cloud-1";
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
    ../../../home/core
    ../../../users/${username}/home.nix
    (_: {
      home = {
        inherit username;
        homeDirectory = "/home/${username}";
        stateVersion = "26.05";
      };
    })
  ];
}
