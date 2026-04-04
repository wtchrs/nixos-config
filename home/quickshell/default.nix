{ pkgs, inputs, ... }:

let
  awkFile = pkgs.writeText "quickshell-program-list.awk" (builtins.readFile ./scripts/quickshell-program-list.awk);

  renderedScript = pkgs.replaceVars ./scripts/quickshell-program-list.sh {
    awkFile = "${awkFile}";
    awk = "${pkgs.gawk}/bin/awk";
    find = "${pkgs.findutils}/bin/find";
  };

  quickshellProgramList = pkgs.writeShellScriptBin "quickshell-program-list" (builtins.readFile renderedScript);
in
{
  home.packages = [ quickshellProgramList ];

  programs.quickshell = {
    enable = true;
    package = inputs.quickshell.packages.${pkgs.system}.default;
  };

  xdg.configFile."quickshell".source = ./config;
}
