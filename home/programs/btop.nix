{ config, pkgs, ... }:

let
  package =
    if config.my.features.nvidia.enable then
      pkgs.btop-cuda
    else
      pkgs.btop;
in
{
  programs.btop = {
    enable = true;
    inherit package;

    settings = {
      color_theme = "nord";
      theme_background = false;
    };

    extraConfig = ''
      vim_keys = true
      proc_sorting = "pid"
      proc_reversed = true
      proc_tree = true
      proc_gradient = false
    '';
  };
}
