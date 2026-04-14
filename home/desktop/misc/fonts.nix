{ lib, config, pkgs, ... }:

{
  config = lib.mkIf config.my.features.desktop.enable {
    home.packages = with pkgs; [
      sarasa-gothic
      nerd-fonts.symbols-only
      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji
      source-code-pro
      source-han-mono
      source-han-sans
      source-han-serif
      fira-sans
      fira-code
    ];

    fonts = {
      fontconfig.enable = true;

      fontconfig.defaultFonts = {
        emoji = [ "Noto Color Emoji" ];
        monospace = [ "Sarasa Mono K" ];
        sansSerif = [ "Noto Sans CJK SC" ];
        serif = [ "Source Han Serif" ];
      };
    };
  };
}
