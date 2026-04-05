inputs@{ nixpkgs, home-manager, ... }:

let
  inherit (nixpkgs) lib;
  profiles = import ./profiles.nix { inherit lib; };
in

_: hostConfig:
let
  userConfig = import hostConfig.userModule;
  inherit (userConfig) username;
  hostHomeOverrides = hostConfig.homeOverrides or [ ];
in
nixpkgs.lib.nixosSystem {
  inherit (hostConfig) system;

  specialArgs = {
    inherit username inputs;
  };

  modules = [
    {
      nixpkgs.config.allowUnfree = true;

      nixpkgs.overlays = [
        inputs.nix-cachyos-kernel.overlays.pinned
        inputs.niri.overlays.niri
        (import ../../overlays/sarasa-mono-k-nerd-font.nix)
      ];

      networking.hostName = lib.mkDefault hostConfig.hostName;
    }

    hostConfig.hostModule

    home-manager.nixosModules.home-manager
    {
      home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        extraSpecialArgs = {
          inherit username inputs;
        };
        users.${username}.imports =
          (profiles.getHomeModules hostConfig.homeProfiles) ++ userConfig.homeModules ++ hostHomeOverrides;
      };
    }
  ]
  ++ (profiles.getSystemModules hostConfig.systemProfiles)
  ++ userConfig.nixosModules;
}
