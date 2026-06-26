{
  self,
  inputs,
  ...
}:

let
  inherit (self.nixos-unified.lib) mkLinuxSystem;

  mkNixos = mkLinuxSystem { home-manager = false; };
in
{
  flake = {
    nixosConfigurations = {
      notebook = mkNixos (import ../../configurations/nixos/notebook { inherit inputs; });
      vm = mkNixos (import ../../configurations/nixos/vm { inherit inputs; });
      srv-cloud-2 = mkNixos (import ../../configurations/nixos/srv-cloud-2 { inherit inputs; });
    };

    homeConfigurations = {
      "wtchrs@archlinux" = import (../../configurations/home + "/wtchrs@archlinux") { inherit inputs; };
      "wtchrs@srv-cloud-1" = import (../../configurations/home + "/wtchrs@srv-cloud-1") {
        inherit inputs;
      };
    };
  };
}
