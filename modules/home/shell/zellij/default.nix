{ lib, pkgs, ... }:

{
  programs.zellij = {
    enable = true;
    extraConfig =
      lib.replaceStrings
        [ "@zjstatus@" "@hostname@" ]
        [ "${pkgs.zellijPlugins.zjstatus}" "${pkgs.net-tools}/bin/hostname" ]
        (builtins.readFile ./kdl/config.kdl);
    layouts.default = ./kdl/layout.kdl;
  };
}
