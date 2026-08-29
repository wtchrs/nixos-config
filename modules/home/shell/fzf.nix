{ lib, pkgs, ... }:

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
      # zoxide items
      ${pkgs.zoxide}/bin/zoxide query --list --score |
        ${pkgs.gawk}/bin/awk '{
          score = $1
          sub(/^[[:space:]]*[^[:space:]]+[[:space:]]+/, "")
          printf "%s\t%s\n", $0, score
        }'

      # all directories
      ${pkgs.fd}/bin/fd --absolute-path --type=d --hidden --exclude .git |
        ${pkgs.gawk}/bin/awk '{ printf "%s\t-\n", $0 }'
    } | ${pkgs.gawk}/bin/awk -F '\t' '!seen[$1]++'
  '';
in
{
  programs.fzf = {
    enable = true;
    enableZshIntegration = true;

    defaultCommand = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";
    fileWidget.command = "${pkgs.fd}/bin/fd --hidden --strip-cwd-prefix --exclude .git";

    changeDirWidget = {
      command = "${fzfAltCCommand}";
      options = [
        "--no-sort"
        "--scheme=history"
        "--with-nth='{2}\t{1}'"
        "--accept-nth=1"
        "--preview '${fzfLsdPreview} {1}'"
        "--preview-window=down,30%,sharp"
      ];
    };

    # Disable fzf Ctrl+R binding to avoid conflicts with atuin
    historyWidget.command = "";
  };

  # Override the default zoxide `zi` command with fzf directory picker
  programs.zsh.initContent = lib.mkOrder 1100 ''
    function zi() {
      setopt localoptions pipefail no_aliases 2>/dev/null

      local result
      local query="''${(j: :)@}"

      result="$(
        FZF_DEFAULT_COMMAND=''${FZF_ALT_C_COMMAND:-} \
        FZF_DEFAULT_OPTS=$(__fzf_defaults \
          "--reverse --walker=dir,follow,hidden --scheme=path" \
          "''${FZF_ALT_C_OPTS-} +m") \
        FZF_DEFAULT_OPTS_FILE="" \
          $(__fzfcmd) --query "$query" < /dev/tty
      )" || return

      [[ -n "$result" ]] && builtin cd -- "$result"
    }
  '';
}
