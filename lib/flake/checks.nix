{
  nixpkgs,
  hosts,
  nixosConfigurations,
}:

let
  inherit (nixpkgs) lib;
  systems = lib.unique (map (host: host.system) (builtins.attrValues hosts));
  repoRoot = ../..;
  mkPkgs = system: import nixpkgs { inherit system; };

  perSystem =
    builder:
    builtins.listToAttrs (
      map (system: {
        name = system;
        value = builder system;
      }) systems
    );
in
{
  formatter = perSystem (system: (mkPkgs system).nixfmt-rfc-style);

  checks = perSystem (
    system:
    let
      pkgs = mkPkgs system;
      hostChecks = lib.mapAttrs' (
        name: config: lib.nameValuePair "nixos-${name}" config.config.system.build.toplevel
      ) (lib.filterAttrs (name: _: hosts.${name}.system == system) nixosConfigurations);
      statixCheck = pkgs.runCommand "statix-check" { nativeBuildInputs = [ pkgs.statix ]; } ''
        cd ${repoRoot}
        statix check .
        touch $out
      '';
    in
    hostChecks
    // {
      statix = statixCheck;
    }
  );
}
