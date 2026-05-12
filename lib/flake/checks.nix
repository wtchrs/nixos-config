{
  nixpkgs,
  hosts,
  nixosConfigurations,
  homeConfigurations,
}:

let
  inherit (nixpkgs) lib;

  systemHosts = hosts.system;
  homeHosts = hosts.home;
  allTargets = builtins.attrValues systemHosts ++ builtins.attrValues homeHosts;

  systems = lib.unique (map (host: host.system) allTargets);
  repoRoot = ../..;
  mkPkgs = system: import nixpkgs { inherit system; };

  perSystem =
    builder:
    builtins.listToAttrs (
      lib.flip map systems (system: {
        name = system;
        value = builder system;
      })
    );
in
{
  formatter = perSystem (system: (mkPkgs system).nixfmt);

  checks = perSystem (
    system:
    let
      pkgs = mkPkgs system;

      hostChecks = lib.mapAttrs' (
        name: config:
        lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel
      ) (lib.filterAttrs (name: _: systemHosts.${name}.system == system) nixosConfigurations);

      homeChecks =
        lib.mapAttrs' (name: config: lib.nameValuePair "home-${name}" config.activationPackage)
          (lib.filterAttrs (_: config: config.pkgs.stdenv.hostPlatform.system == system) homeConfigurations);

      statixCheck = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${repoRoot}
        statix check .
        touch $out
      '';
    in
    hostChecks // homeChecks // { statix = statixCheck; }
  );
}
