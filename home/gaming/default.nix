{
  lib,
  config,
  pkgs,
  osConfig ? null,
  ...
}:

let
  cfg = config.my.features.gaming;
  inherit (cfg) proton;
  steamCompatManagedByNixOS = osConfig != null && (osConfig.programs.steam.enable or false);

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

  common = pkgs.replaceVarsWith {
    src = ./umu-exe-common.sh;
    replacements = {
      protonName = proton.name;
      protonPath = "${proton.package.steamcompattool}";
    };
  };

  launcher = pkgs.writeShellApplication {
    name = "umu-exe-universal";
    runtimeInputs = runtimePackages ++ helperPackages;
    text = builtins.replaceStrings
      [
        "@umuExeCommon@"
      ]
      [
        "${common}"
      ]
      (builtins.readFile ./umu-exe-universal.sh);
  };

  setup = pkgs.writeShellApplication {
    name = "umu-exe-prefix-setup";
    runtimeInputs = runtimePackages ++ helperPackages;
    text = builtins.replaceStrings
      [
        "@umuExeCommon@"
      ]
      [
        "${common}"
      ]
      (builtins.readFile ./umu-exe-prefix-setup.sh);
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
    runtimeInputs =
      with pkgs;
      [
        coreutils
        findutils
        jq
      ]
      ++ [ exeIcon ];
    text = builtins.readFile ./umu-exe-list.sh;
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

  mimeDefaultCommands = lib.concatMapStringsSep "\n" (
    mimeType:
    "run ${pkgs.xdg-utils}/bin/xdg-mime default ${lib.escapeShellArg desktopFile} ${lib.escapeShellArg mimeType}"
  ) windowsMimeTypes;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      launcher
      setup
      exeIcon
      exeList
    ]
    ++ runtimePackages;

    xdg.dataFile = lib.mkIf (!steamCompatManagedByNixOS) {
      "Steam/compatibilitytools.d/${proton.name}".source = proton.package.steamcompattool;
    };

    xdg.desktopEntries.umu-exe-universal = {
      name = "UMU ${proton.name}";
      genericName = "Windows Program Launcher";
      comment = "Run Windows executables with UMU and ${proton.name}";
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
