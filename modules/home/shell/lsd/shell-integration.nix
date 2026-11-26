{ lib, pkgs, ... }:

let
  # Compute LS_COLORS once at build time: the dircolors defaults, then the eza
  # rules from ls_colors.sh. The shells set the whole value, so a nested shell
  # does not append the rules to an inherited LS_COLORS again.
  lsColors = pkgs.runCommand "ls-colors.sh" { } ''
    # dircolors selects its color rules by TERM.
    export TERM=xterm-256color
    eval "$(${pkgs.coreutils}/bin/dircolors --bourne-shell)"
    source ${./ls_colors.sh}
    printf 'export LS_COLORS=%q\n' "$LS_COLORS" > "$out"
  '';
in
{
  programs.bash.initExtra = ''
    source ${lsColors}
  '';

  # Before the completion zstyles, which read LS_COLORS.
  programs.zsh.initContent = lib.mkOrder 550 ''
    source ${lsColors}
  '';
}
