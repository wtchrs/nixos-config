{ pkgs, ... }:

{
  home.packages = [ pkgs.nix-output-monitor ];

  programs = {
    direnv.enable = true;
    direnv.nix-direnv.enable = true;
  };
}
