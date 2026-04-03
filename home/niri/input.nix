_:

{
  programs.niri.settings.input = {
    keyboard = {
      xkb = {
        layout = "us";
        options = "ctrl:nocaps";
      };
      repeat-delay = 250;
    };

    touchpad = {
      tap = true;
      dwt = true;
      dwtp = true;
      drag = true;
      drag-lock = true;
      natural-scroll = true;
      tap-button-map = "left-right-middle";
    };

    # Prevent from moving focus if scrolling is required.
    focus-follows-mouse = {
      enable = true;
      max-scroll-amount = "0%";
    };
  };
}
