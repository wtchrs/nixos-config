{
  self,
  inputs,
  ...
}:

let
  inherit (inputs.nixpkgs) lib;
  inherit (self.nixos-unified.lib) mkLinuxSystem;

  hosts = import ../../hosts.nix;
  mkHostModule = import ../../lib/mkHost.nix inputs;
  mkHome = import ../../lib/mkHome.nix inputs;

  mkNixos = mkLinuxSystem { home-manager = false; };
in
{
  flake = {
    nixosConfigurations = lib.mapAttrs (name: host: mkNixos (mkHostModule name host)) hosts.system;

    homeConfigurations = lib.flip lib.mapAttrs' hosts.home (
      name: target:
      let
        profileName = target.profileName or "${target.user}@${target.hostName or name}";
      in
      lib.nameValuePair profileName (mkHome name target)
    );
  };
}
