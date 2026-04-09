{ nixpkgs, hosts, ... }:

let
  inherit (nixpkgs) lib;
  systems = lib.unique (map (host: host.system) (builtins.attrValues hosts));

  perSystem =
    builder:
    builtins.listToAttrs (
      map (system: {
        name = system;
        value = builder system;
      }) systems
    );
in
perSystem (
  system:
  let
    pkgs = import nixpkgs { inherit system; };
  in
  {
    default = pkgs.mkShell {
      packages = with pkgs; [
        nil
        nixd
        statix
      ];

      shellHook = ''
        echo "Entered NixOS configuration flake dev shell"
      '';
    };
  }
)
