{ inputs, ... }:

{
  imports = [
    inputs.nixos-unified.flakeModules.default

    ./modules.nix
    ./configurations.nix
    ./devShells.nix
    ./checks.nix
  ];
}
