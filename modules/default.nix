_:

{
  imports = [
    ./options/features.nix

    ./core/base.nix
    ./core/cache.nix
    ./core/workstation.nix

    ./features/desktop
    ./features/nvidia.nix
    ./features/gaming.nix
  ];
}
