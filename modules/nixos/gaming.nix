{
  flake,
  lib,
  pkgs,
  ...
}:

let
  inherit (flake) self;
  proton = self.lib.proton-runtime { inherit lib pkgs; };
in
{
  inherit (proton) assertions;

  environment.systemPackages = with pkgs; [
    mangohud
    gamemode
    umu-launcher
  ];

  programs = {
    steam = {
      enable = true;
      extraCompatPackages = [ proton.package ] ++ proton.extraPackages;
    };

    gamescope = {
      enable = true;
    };
  };
}
