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

        #fcitx5-mozc

        # FIX: remove patch override once the patch is merged upstream
        (fcitx5-mozc.override {
          mozc = pkgs.mozc.overrideAttrs (oldAttrs: {
            patches = (oldAttrs.patches or [ ]) ++ [
              (pkgs.fetchurl {
                url = "https://github.com/google/mozc/commit/29c082a64b577b661694148760a2ae19817beb57.patch";
                hash = "sha256-TcuMPd3E4ZPhU4tmeVD7OMY4tWFJGjiiSXZSh3gn384=";
              })
            ];
          });
        })

        fcitx5-nord
        qt6Packages.fcitx5-configtool
      ];
    };
  };
}
