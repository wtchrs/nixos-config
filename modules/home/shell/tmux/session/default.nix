{ pkgs, ... }:

let
  tms = pkgs.stdenvNoCC.mkDerivation {
    pname = "tms";
    version = "0.1.0";

    src = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = pkgs.lib.fileset.unions [
        ./tms
      ];
    };

    nativeBuildInputs = [ pkgs.makeWrapper ];

    installPhase = ''
      runHook preInstall
      install -Dm755 tms "$out/bin/tms"
      patchShebangs "$out/bin/tms"
      wrapProgram "$out/bin/tms" \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.bash
            pkgs.coreutils
            pkgs.tmux
            pkgs.fzf
          ]
        }
      runHook postInstall
    '';
  };
in
{
  home.packages = [ tms ];

  programs.tmux.extraConfig = ''
    bind s run-shell '${tms}/bin/tms'
  '';
}
