{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.my.features;
in
{
  options.my.features = {
    desktop = {
      enable = lib.mkEnableOption "Desktop environment";
      # If desktop.displayManager is disabled, desktop session should be launched in TTY.
      displayManager.enable = lib.mkEnableOption "Display manager setup";
    };

    gaming = {
      enable = lib.mkEnableOption "Gaming setup";

      proton = {
        name = lib.mkOption {
          type = lib.types.str;
          description = "Display name for the Steam compatibility tool used by gaming integrations.";
        };

        package = lib.mkOption {
          type = lib.types.package;
          description = "Steam compatibility tool package used by Steam and UMU integrations.";
        };

        extraPackages = lib.mkOption {
          type = lib.types.listOf lib.types.package;
          description = "Steam compatibility tool package used by Steam";
        };
      };
    };

    nvidia.enable = lib.mkEnableOption "NVIDIA stack";
  };

  # Default configurations and assertions for `my.features.gaming.proton`
  config = {
    my.features.gaming.proton = {
      name = lib.mkDefault "DW-Proton";
      package = lib.mkDefault (pkgs.dwproton-bin.override {
        steamDisplayName = cfg.gaming.proton.name;
      });
      extraPackages = [];
    };

    assertions = lib.mkIf cfg.gaming.enable [
      {
        assertion = cfg.gaming.proton.package ? steamcompattool;
        message = "my.features.gaming.proton.package must provide a steamcompattool output.";
      }
      {
        assertion = lib.all (package: package ? steamcompattool) cfg.gaming.proton.extraPackages;
        message = "Every package in my.features.gaming.proton.extraPackages must provide a steamcompattool output.";
      }
    ];
  };
}
