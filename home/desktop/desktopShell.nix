{ inputs, lib, config, ... }:
{
  imports = [ inputs.nereid-shell.homeManagerModules.default ];

  config = lib.mkIf config.my.features.desktop.enable {
    programs.nereid-shell = {
      enable = true;
      niriIntegration.enable = true;

      programProviders = lib.optionals config.my.features.gaming.enable [
        "${config.home.profileDirectory}/bin/umu-exe-list"
      ];
    };
  };
}
