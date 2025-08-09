{ config, pkgs, ... } :

let
  font = "Sarasa Mono K Nerd Font";
in {
  programs.alacritty = {
    enable = true;
    settings = {
      font = {
        size = 12;
        normal.family = font;
      };

      window = {
        opacity = 0.8;
        padding = {
          x = 15;
          y = 15;
        };
      };

      selection.save_to_clipboard = true;

      colors = {
        bright = {
          black = "#4c566a";
          blue = "#81a1c1";
          cyan = "#8fbcbb";
          green = "#a3be8c";
          magenta = "#b48ead";
          red = "#bf616a";
          white = "#eceff4";
          yellow = "#ebcb8b";
        };

        normal = {
          black = "#3b4252";
          blue = "#81a1c1";
          cyan = "#88c0d0";
          green = "#a3be8c";
          magenta = "#b48ead";
          red = "#bf616a";
          white = "#e5e9f0";
          yellow = "#ebcb8b";
        };

        dim = {
          black = "#373e4d";
          blue = "#68809a";
          cyan = "#6d96a5";
          green = "#809575";
          magenta = "#8c738c";
          red = "#94545d";
          white = "#aeb3bb";
          yellow = "#b29e75";
        };

        primary = {
          # background = "#2e3440";
          dim_foreground = "#a5abb6";
          foreground = "#d8dee9";
        };

        cursor = {
          cursor = "#d8dee9";
          text = "#2e3440";
        };

        vi_mode_cursor = {
          cursor = "#d8dee9";
          text = "#2e3440";
        };
      };
    };
  };
}
