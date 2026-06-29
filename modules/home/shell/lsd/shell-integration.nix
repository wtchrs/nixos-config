{ pkgs, ... }:

let
  lsColors = pkgs.writeText "ls_colors.sh" (builtins.readFile ./ls_colors.sh);
in {
  programs.bash.initExtra = ''
    source ${lsColors}
  '';

  programs.zsh.initContent = ''
    source ${lsColors}
  '';
}
