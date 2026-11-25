{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.neovim = import ../../packages/neovim/nix/package.nix { inherit pkgs lib; };
      packages.zsh-startup = pkgs.callPackage ../../packages/zsh-startup/package.nix { };
    };
}
