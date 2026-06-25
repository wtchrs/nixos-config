{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          nil
          nixd
          statix
        ];

        shellHook = ''
          echo "Entered NixOS configuration flake dev shell"
        '';
      };
    };
}
