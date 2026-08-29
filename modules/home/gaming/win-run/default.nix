{
  config,
  flake,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:

let
  inherit (flake) self;
  proton = self.lib.gaming-proton { inherit lib pkgs; };
  steamCompatManagedByNixOS = osConfig != null && (osConfig.programs.steam.enable or false);
  cfg = config.programs.win-run;

  winRunText =
    builtins.replaceStrings
      [
        "@protonPath@"
        "@umuRun@"
      ]
      [
        "${proton.package.steamcompattool}"
        (lib.getExe pkgs.umu-launcher)
      ]
      (builtins.readFile ./win-run.py);

  winRun = pkgs.writeScriptBin "win-run" ''
    #!${pkgs.python3}/bin/python3
    ${winRunText}
  '';

  windowsMimeTypes = {
    exe = [
      "application/vnd.microsoft.portable-executable"
      "application/x-dosexec"
      "application/x-ms-dos-executable"
      "application/x-msdownload"
      "application/x-msdos-program"
      "application/x-wine-extension-exe"
    ];
    msi = [
      "application/x-msi"
      "application/x-ms-installer"
      "application/x-wine-extension-msi"
    ];
  };
  allWindowsMimeTypes = windowsMimeTypes.exe ++ windowsMimeTypes.msi;
in
{
  options.programs.win-run.mimeAssociations.enable =
    lib.mkEnableOption "win-run as the default EXE and MSI handler";

  config = {
    inherit (proton) assertions;

    home.packages = [
      winRun
      pkgs.umu-launcher
    ];

    # Tray icon integration
    services.xembed-sni-proxy.enable = true;

    xdg = {
      dataFile = lib.mkIf (!steamCompatManagedByNixOS) {
        "Steam/compatibilitytools.d/${proton.name}".source = proton.package.steamcompattool;
      };

      desktopEntries.win-run = {
        name = "Win Run (${proton.name})";
        genericName = "Windows Program Launcher";
        comment = "Open Windows executables in the default win-run workspace";
        exec = "${winRun}/bin/win-run open %f";
        terminal = false;
        type = "Application";
        categories = [
          "Game"
          "Utility"
        ];
        mimeType = allWindowsMimeTypes;
        noDisplay = false;
      };

      mimeApps = lib.mkIf cfg.mimeAssociations.enable {
        enable = true;
        defaultApplications = lib.genAttrs allWindowsMimeTypes (_: [ "win-run.desktop" ]);
      };
    };
  };
}
