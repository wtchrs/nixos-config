{ inputs, ... }:

{
  imports = [
    inputs.nixos-unified.flakeModules.default

    ./configurations.nix
    ./devShells.nix
    ./checks.nix
  ];
}
