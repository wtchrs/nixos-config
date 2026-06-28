{
  flake,
  lib,
  pkgs,
  ...
}:

let
  inherit (flake) self;
  proton = self.lib.gaming-proton { inherit lib pkgs; };
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
