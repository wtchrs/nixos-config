{
  self,
  inputs,
  ...
}:

let
  inherit (self.nixos-unified.lib) mkHomeConfiguration mkLinuxSystem;

  mkNixos = mkLinuxSystem { home-manager = false; };

  mkPkgs =
    system:
    import inputs.nixpkgs {
      inherit system;
      overlays = builtins.attrValues self.overlays;
      config.allowUnfree = true;
    };

  mkHome = system: module: mkHomeConfiguration (mkPkgs system) module;
in
{
  flake = {
    nixosConfigurations = {
      notebook = mkNixos ../../configurations/nixos/notebook;
      vm = mkNixos ../../configurations/nixos/vm;
      srv-cloud-2 = mkNixos ../../configurations/nixos/srv-cloud-2;
    };

    homeConfigurations = {
      "wtchrs@archlinux" = mkHome "x86_64-linux" (../../configurations/home + "/wtchrs@archlinux");
      "wtchrs@srv-cloud-1" = mkHome "aarch64-linux" (../../configurations/home + "/wtchrs@srv-cloud-1");
    };
  };
}
