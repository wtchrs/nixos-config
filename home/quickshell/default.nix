{ pkgs, inputs, ... }:

let
  inherit (pkgs.stdenv.hostPlatform) system;

  awkFile = pkgs.writeText "quickshell-program-list.awk" (
    builtins.readFile ./scripts/quickshell-program-list.awk
  );

  quickshellProgramList = pkgs.replaceVarsWith {
    src = ./scripts/quickshell-program-list.sh;
    replacements = {
      awkFile = "${awkFile}";
      awk = "${pkgs.gawk}/bin/awk";
      find = "${pkgs.findutils}/bin/find";
    };
    dir = "bin";
    isExecutable = true;
  };
in
{
  home.packages = [ quickshellProgramList ];

  programs.quickshell = {
    enable = true;
    package = inputs.quickshell.packages.${system}.default;
  };

  xdg.configFile."quickshell".source = ./config;
}
