{ pkgs, ... }:

let
  fzfLsdPreview = pkgs.writeShellScript "fzf-lsd-preview" ''
    export _FZF_LSD_PREVIEW_PATH="$1"

    exec ${pkgs.util-linux}/bin/script \
      --quiet \
      --return \
      --command '
        ${pkgs.coreutils}/bin/stty rows "$FZF_PREVIEW_LINES" cols "$FZF_PREVIEW_COLUMNS";
        exec ${pkgs.lsd}/bin/lsd --color=always --icon=always --group-directories-first -- "$_FZF_LSD_PREVIEW_PATH"
      ' \
      /dev/null
  '';

  fzfAltCCommand = pkgs.writeShellScript "fzf-alt-c-command" ''
    {
      ${pkgs.zoxide}/bin/zoxide query --list
      ${pkgs.fd}/bin/fd --absolute-path --type=d --hidden --exclude .git
    } | ${pkgs.gawk}/bin/awk '!seen[$0]++'
  '';
in
{
  imports = [
    ./zsh.nix
    ./starship.nix
    ./atuin.nix
    ./tmux
    ./zellij
    ./lsd
    ./colored-man.nix
  ];

  home.packages = with pkgs; [
    fd
    rgrc
  ];

  programs = {
    bat = {
      enable = true;
      config = {
        theme = "Nord";
      };
    };

    fzf = {
      enable = true;
      enableZshIntegration = true;

      defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
      fileWidget.command = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";

      changeDirWidget = {
        command = "${fzfAltCCommand}";
        options = [
          "--no-sort"
          "--scheme=history"
          "--preview '${fzfLsdPreview} {}'"
          "--preview-window=down,30%,sharp"
        ];
      };

      # Disable fzf Ctrl+R binding to avoid conflicts with atuin
      historyWidget.command = "";
    };

    broot = {
      enable = true;
      enableZshIntegration = true;
    };

    zoxide = {
      enable = true;
      enableBashIntegration = true;
      enableZshIntegration = true;
    };

    bash = {
      enable = true;
      enableCompletion = true;

      bashrcExtra = ''
        export PATH="$PATH:$HOME/.local/bin"
      '';

      initExtra = ''
        eval "$(${pkgs.rgrc}/bin/rgrc --aliases --except ls)"
      '';

      shellAliases = {
        bat = "bat --paging=never";
      };
    };
  };
}
