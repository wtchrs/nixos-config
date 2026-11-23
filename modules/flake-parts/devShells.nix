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

          # Lua
          stylua
          lua-language-server

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
