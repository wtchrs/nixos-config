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
      # Recently visited directories from zoxide.
      ${pkgs.zoxide}/bin/zoxide query --list --score |
        ${pkgs.gawk}/bin/awk -v home="$HOME" '{
          score = $1
          sub(/^[[:space:]]*[^[:space:]]+[[:space:]]+/, "")

          path = $0
          display = path

          if (path == home)
            display = "~"
          else if (index(path, home "/") == 1)
            display = "~" substr(path, length(home) + 1)

          printf "%s\trecent\t%s\t%s\n", path, score, display
        }'

      # Directories below the current working directory.
      ${pkgs.fd}/bin/fd \
        --absolute-path \
        --type=d \
        --hidden \
        --exclude .git |
        ${pkgs.gawk}/bin/awk -v cwd="$PWD" '{
          path = $0

          if (cwd == "/")
            display = "." path
          else if (index(path, cwd "/") == 1)
            display = "." substr(path, length(cwd) + 1)
          else
            display = path

          printf "%s\tlocal\t-\t%s\n", path, display
        }'
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
        "--scheme=path"
        "--filepath-word"
        "--highlight-line"

        "--delimiter='\\t'"

        # --nth is evaluated after --with-nth.
        "--with-nth='{2}\t{3}\t{4}'"
        "--nth=3"

        "--accept-nth=1"

        "--prompt='search> '"
        "--info=inline-right"
        "--bind='ctrl-s:toggle-sort'"
        "--bind='ctrl-/:toggle-preview'"

        "--header='Enter: move  Esc: cancel  Ctrl-S: sort  Ctrl-/: preview'"

        "--preview '${fzfLsdPreview} {1}'"
        "--preview-window='right,50%,sharp,<80(down,40%,sharp)'"
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
