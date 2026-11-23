{ inputs, ... }:

{
  imports = [
    inputs.nixos-unified.flakeModules.default

    ./modules.nix
    ./packages.nix
    ./configurations.nix
    ./devShells.nix
    ./checks.nix
  ];
}
