{ pkgs, ... }:

let
  tms = pkgs.buildGoModule {
    pname = "tms";
    version = "0.1.0";

    src = pkgs.lib.fileset.toSource {
      root = ./.;
      fileset = pkgs.lib.fileset.unions [
        ./go.mod
        ./go.sum
        ./manager/app.go
        ./manager/main.go
        ./preview/main.go
        ./preview/main_test.go
      ];
    };

    vendorHash = "sha256-tu7F1okmXaT/VsO5heKRLV3bczPjBJJo1ML2hYou2EE=";
    subPackages = [ "manager" ];
    nativeBuildInputs = [ pkgs.makeWrapper ];

    postInstall = ''
      mv "$out/bin/manager" "$out/bin/tms"
      wrapProgram "$out/bin/tms" \
        --prefix PATH : ${
          pkgs.lib.makeBinPath [
            pkgs.tmux
            pkgs.fzf
          ]
        }
    '';
  };
in
{
  home.packages = [ tms ];

  programs.tmux.extraConfig = ''
    bind s run-shell '${tms}/bin/tms'
    bind S choose-tree -Zs
  '';
}
