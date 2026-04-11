{
  nixpkgs,
  hosts,
  nixosConfigurations,
  homeConfigurations,
}:

let
  inherit (nixpkgs) lib;
  systems = lib.unique (map (host: host.system) (builtins.attrValues hosts));
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

      hostChecks =
        lib.mapAttrs'
          (name: config: lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel)
          (lib.filterAttrs (name: _: hosts.${name}.system == system) nixosConfigurations);

      homeChecks =
        lib.mapAttrs'
          (name: config: lib.nameValuePair "home-${name}" config.activationPackage)
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
