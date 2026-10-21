{ pkgs, ... }:

{
  # dependencies for external programs(IDEs)
  programs.nix-ld.enable = true;
  programs.nix-ld.libraries =
    pkgs.appimageTools.defaultFhsEnvArgs.multiPkgs pkgs
    ++ (with pkgs; [
      gtk3

      icu
      libclang.lib
      libxcrypt-legacy
      stdenv.cc.cc

      fuse
      fuse3
    ]);
}
