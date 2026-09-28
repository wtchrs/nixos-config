{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = with pkgs; [
          # Nix
          nil
          nixd
          nixfmt
          statix

          # Go
          go
          gopls
          golangci-lint
        ];

        shellHook = ''
          echo "Entered NixOS configuration flake dev shell"
        '';
      };
    };
}
