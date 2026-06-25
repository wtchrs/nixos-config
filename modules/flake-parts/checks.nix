{
  config,
  inputs,
  root,
  ...
}:

let
  inherit (inputs.nixpkgs) lib;

  flakeConfig = config;
  hosts = import (root + /hosts.nix);

  homeProfileName = name: target: target.profileName or "${target.user}@${target.hostName or name}";
in
{
  perSystem =
    { system, pkgs, ... }:
    let
      systemHosts = lib.filterAttrs (_: host: host.system == system) hosts.system;
      homeHosts = lib.filterAttrs (_: target: target.system == system) hosts.home;

      hostChecks = lib.mapAttrs' (
        name: _:
        lib.nameValuePair "nixos-${name}"
          flakeConfig.flake.nixosConfigurations.${name}.config.system.build.toplevel
      ) systemHosts;

      homeChecks = lib.mapAttrs' (
        name: target:
        let
          profileName = homeProfileName name target;
        in
        lib.nameValuePair "home-${profileName}"
          flakeConfig.flake.homeConfigurations.${profileName}.activationPackage
      ) homeHosts;

      statixCheck = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${root}
        statix check .
        touch $out
      '';
    in
    {
      formatter = pkgs.nixfmt;
      checks = hostChecks // homeChecks // { statix = statixCheck; };
    };
}
