{ lib, pkgs, ... }:

{
  home.packages = lib.optional (lib.meta.availableOn pkgs.stdenv.hostPlatform pkgs.twintaillauncher) pkgs.twintaillauncher;
}
