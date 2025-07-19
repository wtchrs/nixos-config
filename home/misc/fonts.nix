{ pkgs, ... } :

{
  fonts = {
    fontconfig.enable = true;

    fontconfig.defaultFonts = {
      emoji = [ "Noto Color Emoji" ];
      monospace = [ "Source Han Mono" "Iosevka Nerd Font" ];
      sansSerif = [ "Noto Sans CJK SC" ];
      serif = [ "Source Han Serif" ];
    };
  };
}
