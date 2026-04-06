{ pkgs, ... }:

{
  i18n = {
    # defaultLocale = "en_US.UTF-8";

    inputMethod = {
      enable = true;
      type = "fcitx5";

      fcitx5 = {
        addons = with pkgs; [
          fcitx5-gtk
          kdePackages.fcitx5-qt
          fcitx5-hangul
          fcitx5-mozc
          qt6Packages.fcitx5-configtool
        ];

        waylandFrontend = true;
        ignoreUserConfig = false;

        settings = {
          inputMethod = {
            GroupOrder."0" = "KO";
            GroupOrder."1" = "JA";

            # Korean group: Eng, Hangul
            "Groups/0" = {
              Name = "KO";
              "Default Layout" = "us";
              DefaultIM = "hangul";
            };
            "Groups/0/Items/0".Name = "keyboard-us";
            "Groups/0/Items/1" = {
              Name = "hangul";
              Layout = "us";
            };

            # Japanese group: Eng, Mozc
            "Groups/1" = {
              Name = "JA";
              "Default Layout" = "us";
              DefaultIM = "mozc";
            };
            "Groups/1/Items/0".Name = "keyboard-us";
            "Groups/1/Items/1" = {
              Name = "mozc";
              Layout = "us";
            };
          };

          globalOptions = {
            Behavior = {
              ActiveByDefault = "False";
            };

            Hotkey = {
              EnumerateWithTriggerKeys = "False";
              EnumerateSkipFirst = "False";
              ModifierOnlyKeyTimeout = "250";
            };

            "Hotkey/TriggerKeys" = {
              # RAlt -> Hangul
              "0" = "Hangul";
            };

            # Switch between KO and JA groups
            "Hotkey/EnumerateGroupForwardKeys" = {
              # RCtrl -> Hangul_Hanja
              "0" = "Hangul_Hanja";
            };
          };
        };
      };
    };
  };
}
