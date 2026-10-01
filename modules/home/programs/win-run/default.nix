{
  flake,
  lib,
  pkgs,
  osConfig ? null,
  ...
}:

let
  inherit (flake) self;
  proton = self.lib.proton-runtime { inherit lib pkgs; };
  steamCompatManagedByNixOS = osConfig != null && (osConfig.programs.steam.enable or false);

  winRun = pkgs.callPackage ./package.nix {
    protonRuntime = proton.package.steamcompattool;
  };

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
        comment = "Open Windows executables in the default win-run prefix";
        exec = "${winRun}/bin/win-run open %f";
        terminal = false;
        type = "Application";
        categories = [ "Utility" ];
        mimeType = allWindowsMimeTypes;
        noDisplay = true;
      };
    };
  };
}
