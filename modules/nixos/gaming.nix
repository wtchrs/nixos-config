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
    umu-launcher
  ];

  programs = {
    gamemode.enable = true;

    steam = {
      enable = true;
      extraCompatPackages = [ proton.package ] ++ proton.extraPackages;
    };

    gamescope = {
      enable = true;
    };
  };
}
