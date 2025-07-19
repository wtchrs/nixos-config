{ pkgs, ... } :

{
  home.packages = with pkgs; [
    fcitx5
    fcitx5-gtk
    fcitx5-hangul
    fcitx5-configtool
  ];

  i18n.inputMethod = {
    type = "fcitx5";
    fcitx5.addons = with pkgs; [ fcitx5-hangul ];
  };
}
