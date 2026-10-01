{
  lib,
  buildGoModule,
  dwproton-bin,
  umu-launcher,
  protonRuntime ? (dwproton-bin.override { steamDisplayName = "DW-Proton"; }).steamcompattool,
}:

buildGoModule {
  pname = "win-run";
  version = "1.0.0";
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.fileFilter (file: file.hasExt "go" || file.name == "go.mod") ./.;
  };
  vendorHash = null;
  subPackages = [ "manager" ];
  ldflags = [
    "-s"
    "-w"
    "-X main.defaultProton=${protonRuntime}"
    "-X main.defaultUMU=${lib.getExe umu-launcher}"
  ];
  postInstall = ''
    mv "$out/bin/manager" "$out/bin/win-run"
  '';
  checkPhase = ''
    runHook preCheck
    go test ./...
    runHook postCheck
  '';
  meta = {
    description = "Launch Windows programs with Proton and UMU";
    mainProgram = "win-run";
    platforms = lib.platforms.linux;
  };
}
