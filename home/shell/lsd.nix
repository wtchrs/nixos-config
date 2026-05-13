{ pkgs, ... }:

{
  programs.lsd = {
    enable = true;
    enableBashIntegration = true;
    enableZshIntegration = true;

    colors = pkgs.fetchurl {
      url = "https://raw.githubusercontent.com/mstill3/lsd-nord-theme/7f221b491dc72a4c077ebae3a009b901757b89e0/nord.yaml";
      hash = "sha256-2l1cz1gejkvE8gDrqLwz1ZnVHgk2x9TfhGqeOtatxfE=";
    };

    icons = {
      filetype = {
        dir = "";
        file = "";
      };
      extension = {
        md = "";
        markdown = "";
      };
      name = {
        ".envrc" = "";
        # git
        ".gitattributes" = "󰊢";
        ".gitconfig" = "󰊢";
        gitignore_global = "󰊢";
        ".gitignore" = "󰊢";
        ".gitmodules" = "󰊢";
        # doc
        readme = "󰂺";
        "readme.md" = "󰂺";
        todo = "";
        "todo.md" = "";
        # node
        ".node_repl_history" = "";
        "package.json" = "";
      };
    };

    settings = {
      classic = false;
      color.when = "auto";
    };
  };
}
