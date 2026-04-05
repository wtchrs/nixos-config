{ config, pkgs, ... }:

{
  programs.ghostty = {
    enable = true;

    settings = {
      theme = "nord";
      title = " Ghostty";
      term = "xterm-256color";

      # Ghostty has its own nerd font support
      font-family = "Sarasa Mono K";
      font-size = 13;
      font-feature = [
        "-calt"
        "-liga"
        "-dlig"
      ];

      adjust-cell-height = 1;
      adjust-font-baseline = -1;

      window-padding-x = 4;
      window-padding-y = 4;
      window-padding-balance = false;

      unfocused-split-opacity = 0.8;

      clipboard-read = "allow";
      clipboard-write = "allow";
      #copy-on-select = "clipboard";

      mouse-scroll-multiplier = 1;

      window-inherit-working-directory = false;
      gtk-single-instance = false;
    };

    themes = {
      nord = {
        background = "#000000";
        foreground = "#eceff4";
        cursor-color = "#d8dee9";
        background-opacity = 0.65;

        cursor-style = "block";
        shell-integration-features = "no-cursor";
        adjust-cursor-thickness = 1;

        palette = [
          # black
          "0=#3b4252"
          "8=#4c566a"
          # red
          "1=#bf616a"
          "9=#bf616a"
          # green
          "2=#a3be8c"
          "10=#a3be8c"
          # yellow
          "3=#ebcb8b"
          "11=#ebcb8b"
          # blue
          "4=#81a1c1"
          "12=#81a1c1"
          # magenta
          "5=#b48ead"
          "13=#b48ead"
          # cyan
          "6=#88c0d0"
          "14=#8fbcbb"
          # white
          "7=#e5e9f0"
          "15=#eceff4"
        ];
      };
    };
  };
}
