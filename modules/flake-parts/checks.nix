{
  config,
  inputs,
  root,
  ...
}:

let
  inherit (inputs.nixpkgs) lib;

  flakeConfig = config;
in
{
  perSystem =
    { system, pkgs, ... }:
    let
      hostChecks = lib.filterAttrs (_: check: check.system == system) (
        lib.mapAttrs' (
          name: host: lib.nameValuePair "nixos-${name}" host.config.system.build.toplevel
        ) flakeConfig.flake.nixosConfigurations
      );

      homeChecks = lib.filterAttrs (_: check: check.system == system) (
        lib.mapAttrs' (
          name: home: lib.nameValuePair "home-${name}" home.activationPackage
        ) flakeConfig.flake.homeConfigurations
      );

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
