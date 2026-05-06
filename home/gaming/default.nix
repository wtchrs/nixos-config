{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.features.gaming;

  runtimePackages = with pkgs; [
    umu-launcher
    gamemode
    mangohud
    jq
    xrandr
  ];

  helperPackages = with pkgs; [
    coreutils
    findutils
    gnugrep
    gnused
    gawk
  ];

  desktopFile = "umu-exe-universal.desktop";
  dwProtonName = "DW-Proton Latest";
  dwProton = pkgs.dwproton-bin.override {
    steamDisplayName = dwProtonName;
  };

  windowsMimeTypes = [
    "application/vnd.microsoft.portable-executable"
    "application/x-dosexec"
    "application/x-ms-dos-executable"
    "application/x-msdownload"
    "application/x-msi"
    "application/x-ms-installer"
    "application/x-msdos-program"
    "application/x-bat"
    "application/x-wine-extension-exe"
    "application/x-wine-extension-msi"
    "application/x-wine-extension-bat"
    "text/x-msdos-batch"
  ];

  launcher = pkgs.writeShellApplication {
    name = "umu-exe-universal";
    runtimeInputs = runtimePackages ++ helperPackages;
    text = builtins.readFile ./umu-exe-universal.sh;
  };

  exeIcon = pkgs.writeShellApplication {
    name = "umu-exe-icon";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      icoutils
    ];
    text = builtins.readFile ./umu-exe-icon.sh;
  };

  exeList = pkgs.writeShellApplication {
    name = "umu-exe-list";
    runtimeInputs = with pkgs; [
      coreutils
      findutils
      jq
    ] ++ [ exeIcon ];
    text = builtins.readFile ./umu-exe-list.sh;
  };

  mimeDefaultCommands = lib.concatMapStringsSep "\n" (
    mimeType:
    "run ${pkgs.xdg-utils}/bin/xdg-mime default ${lib.escapeShellArg desktopFile} ${lib.escapeShellArg mimeType}"
  ) windowsMimeTypes;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      launcher
      exeIcon
      exeList
    ] ++ runtimePackages;

    xdg.dataFile."Steam/compatibilitytools.d/${dwProtonName}".source = dwProton.steamcompattool;

    xdg.desktopEntries.umu-exe-universal = {
      name = "UMU DW-Proton";
      genericName = "Windows Program Launcher";
      comment = "Run Windows executables with UMU and DW-Proton Latest";
      exec = "${launcher}/bin/umu-exe-universal %f";
      terminal = false;
      type = "Application";
      categories = [
        "Game"
        "Utility"
      ];
      mimeType = windowsMimeTypes;
      noDisplay = false;
    };

    home.activation.umuExeUniversalMimeDefaults = lib.hm.dag.entryAfter [ "installPackages" ] ''
      ${mimeDefaultCommands}
    '';
  };
}
