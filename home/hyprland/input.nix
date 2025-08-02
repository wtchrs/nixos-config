{ ... } :

{
  wayland.windowManager.hyprland.settings = {
    input = {
      # kb_layout = "kr";
      # kb_variant =
      # kb_model =
      kb_options = "ctrl:nocaps"; # Remap caps-lock to ctrl
      # kb_rules =

      follow_mouse = 1;

      touchpad = {
        natural_scroll = false;
      };

      sensitivity = 0; # -1.0 - 1.0, 0 means no modification.

      repeat_delay = 300; # fast repeat input keys
    };
  };
}
