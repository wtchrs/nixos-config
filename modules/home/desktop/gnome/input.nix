{ lib, ... }:

{
  dconf.settings = {
    "org/gnome/desktop/input-sources" = {
      sources = [
        (lib.hm.gvariant.mkTuple [
          "xkb"
          "us"
        ])
      ];
      xkb-options = [
        "ctrl:nocaps"
        "korean:ralt_hangul"
        "korean:rctrl_hanja"
      ];
    };

    "org/gnome/desktop/peripherals/keyboard" = {
      repeat = true;
      delay = lib.hm.gvariant.mkUint32 250;
    };
  };
}
