_:
let
  # Fixed ANSI sequences instead of tput, which costs a process for each value
  # at every shell start. The values match tput for xterm, tmux, and linux.
  initScript = ''
    export LESS_TERMCAP_mb=$'\e[1m\e[31m'
    export LESS_TERMCAP_md=$'\e[1m\e[31m'
    export LESS_TERMCAP_me=$'\e[0m'
    export LESS_TERMCAP_se=$'\e[0m'
    export LESS_TERMCAP_so=$'\e[1m\e[33m\e[44m'
    export LESS_TERMCAP_ue=$'\e[0m'
    export LESS_TERMCAP_us=$'\e[4m\e[1m\e[32m'
    export LESS_TERMCAP_mr=$'\e[7m'
    export LESS_TERMCAP_mh=$'\e[2m'

    export MANPAGER='less'
    export GROFF_NO_SGR=1
  '';
in {
  programs.bash.initExtra = initScript;
  programs.zsh.initContent = initScript;
}
