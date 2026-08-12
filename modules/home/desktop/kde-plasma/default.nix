{ flake, pkgs, ... }:
{
  imports = [
    flake.inputs.plasma-manager.homeModules.plasma-manager
  ];

  programs.plasma = {
    enable = true;

    input = {
      keyboard = {
        layouts = [
          { layout = "us"; }
        ];

        options = [
          "ctrl:nocaps"
          "korean:ralt_hangul"
          "korean:rctrl_hanja"
        ];

        repeatDelay = 250;
      };
    };

    hotkeys.commands.fcitx-toggle = {
      name = "Toggle Fcitx5";
      key = "Hangul";
      command = "${pkgs.fcitx5}/bin/fcitx5-remote -t";
    };
  };
}
