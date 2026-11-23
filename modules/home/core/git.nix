{ config, pkgs, ... }:
let
  # Take the themes from the delta source so they match the installed version.
  deltaThemes = config.programs.delta.package.src;
in
{
  home.packages = with pkgs; [ lazygit ];

  programs = {
    git = {
      enable = true;
      settings = {
        include.path = "${deltaThemes}/themes.gitconfig";

        user = {
          name = "wtchrs";
          email = "wtchr_@outlook.com";
        };
      };
    };

    delta = {
      enable = true;
      enableGitIntegration = true;

      options = {
        features = "arctic-fox";
        width = 10;
        hunk-header-decoration-style = "#5E81AC ul ol";
      };
    };
  };
}
