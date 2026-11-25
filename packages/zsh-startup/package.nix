{
  lib,
  buildGoModule,
}:

buildGoModule {
  pname = "zsh-startup";
  version = "0.1.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./go.mod
      ./go.sum
      ./scripts
      (lib.fileset.fileFilter (file: file.hasExt "go") ./.)
    ];
  };
  vendorHash = "sha256-8lNWbDGva9Jip3W0WWn51OoKLLmnplfhYxgFzR0BAmc=";
  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';
  meta = {
    description = "Measure interactive zsh startup and compare reports";
    mainProgram = "zsh-startup";
  };
}
