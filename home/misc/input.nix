{ pkgs, ... }:

{
  i18n = {
    # defaultLocale = "en_US.UTF-8";

    inputMethod = {
      enable = true;
      type = "fcitx5";
      fcitx5.addons = with pkgs; [
        fcitx5-gtk
        kdePackages.fcitx5-qt
        fcitx5-hangul
        fcitx5-configtool
      ];
    };
  };

  home.sessionVariables = {
    GTK_IM_MODULE = "fcitx";
    QT_IM_MODULE = "fcitx";
    QT4_IM_MODULE = "fcitx";
    QT5_IM_MODULE = "fcitx";
    SDL_IM_MODULE = "fcitx";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
  };
}
