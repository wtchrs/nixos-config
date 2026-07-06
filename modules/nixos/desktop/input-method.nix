{ pkgs, ... }:

{
  # Enable fcitx5 and reuse HM's fcitx5 input method configuration
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";

    fcitx5 = {
      waylandFrontend = true;
      ignoreUserConfig = false;

      addons = with pkgs; [
        fcitx5-gtk
        kdePackages.fcitx5-qt
        fcitx5-hangul
        fcitx5-mozc
        fcitx5-nord
        qt6Packages.fcitx5-configtool
      ];
    };
  };
}
