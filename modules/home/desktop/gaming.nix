{ config, pkgs, ... }:

let
  winRunProvider = pkgs.writeShellScript "nereid-win-run-provider" ''
    ${config.home.profileDirectory}/bin/win-run list
  '';
in
{
  programs.nereid-shell.programProviders = [ winRunProvider ];
}
