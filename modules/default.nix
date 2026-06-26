{ inputs }:

let
  overlays = import ../overlays inputs;
in

{
  imports = [
    inputs.home-manager.nixosModules.home-manager

    ./options/features.nix

    ./core/base.nix
    ./core/cache.nix
    ./core/workstation.nix

    ./features/desktop
    ./features/nvidia.nix
    ./features/gaming.nix
  ];

  nixpkgs = {
    config.allowUnfree = true;
    inherit overlays;
  };

  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    extraSpecialArgs = { inherit inputs; };
  };
}
