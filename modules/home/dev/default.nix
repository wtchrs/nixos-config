{ pkgs, ... }:

{
  imports = [ ./claude-code ];

  home.packages = with pkgs; [
    nodejs
    pnpm
  ];
}
