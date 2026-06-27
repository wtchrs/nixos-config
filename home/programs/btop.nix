{ lib, pkgs, ... }:

{
  programs.btop = {
    enable = true;
    package = lib.mkDefault pkgs.btop;

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
