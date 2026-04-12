{ lib, config, pkgs, ... }:

let
  desktopEnabled = config.my.features.desktop.enable;
in 
{
  config = lib.mkIf desktopEnabled {
    programs.gnome-shell.enable = true;

    gtk = {
      enable = true;

      theme = {
        package = pkgs.mactahoe-gtk-theme;
        name = "MacTahoe-Dark";
      };

      iconTheme = {
        package = pkgs.mactahoe-icon-theme.override {
          themeVariants = [ "blue" ];
        };
        name = "MacTahoe-blue-dark";
      };

      cursorTheme = {
        package = pkgs.mactahoe-icon-theme.override {
          themeVariants = [ "blue" ];
        };
        name = "MacTahoe-Dark";
        size = 24;
      };
    };

    dconf.enable = true;

    home.packages = with pkgs; [
      gnomeExtensions.user-themes
      gnomeExtensions.dash-to-dock
      gnomeExtensions.blur-my-shell
    ];

    dconf.settings = {
      "org/gnome/shell" = {
        enabled-extensions = [
          pkgs.gnomeExtensions.user-themes.extensionUuid
          pkgs.gnomeExtensions.dash-to-dock.extensionUuid
          pkgs.gnomeExtensions.blur-my-shell.extensionUuid
        ];
      };

      "org/gnome/shell/extensions/user-theme" = {
        name = "MacTahoe-Dark";
      };
    };
  };
}
