{
  perSystem =
    { pkgs, lib, ... }:
    {
      packages.neovim = import ../../packages/neovim/nix/package.nix { inherit pkgs lib; };
    };
}
