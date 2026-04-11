{ lib, config, ... }:

{
  imports = [
    ../modules/options/features.nix
    ./core/base.nix
  ];
}
