{ pkgs, ... }:
let
  deltaThemes = pkgs.fetchFromGitHub {
    owner = "dandavison";
    repo = "delta";

    rev = "0.19.2";
    hash = "sha256-vW2mPAxlPXdwqyK/QhU/DOx6MD9u6DDVCDm0OEWm4AQ=";
  };
in {
  home.packages = with pkgs; [ lazygit ];

  programs = {
    git = {
      enable = true;
      settings = {
        include.path = "${deltaThemes}/themes.gitconfig";
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
