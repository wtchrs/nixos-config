{
  wayland.windowManager.niri.settings.input = {
    keyboard = {
      xkb = {
        layout = "us";
        options = "ctrl:nocaps,korean:ralt_hangul,korean:rctrl_hanja";
      };
      repeat-delay = 250;
    };

    touchpad = {
      tap = { };
      dwt = { };
      dwtp = { };
      drag = true;
      drag-lock = { };
      natural-scroll = { };
      tap-button-map = "left-right-middle";
    };

    # Prevent from moving focus if scrolling is required.
    focus-follows-mouse._props.max-scroll-amount = "0%";
  };
}
