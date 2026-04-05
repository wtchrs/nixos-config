{ pkgs, ... }:

{
  fonts = {
    fontconfig.enable = true;

    fontconfig.defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "Sarasa Mono K" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      serif = [ "Source Han Serif" ];
    };
  };
}
