{ ... } :

{
  wayland.windowManager.hyprland.settings = {
    decoration = {
      rounding = 10;

      blur = {
        enabled = true;
        size = 3;
        passes = 1;
      };

      shadow = {
        enabled = true;
        range = 2;
        render_power = 1;
        color = "rgba(1a1a1aee)";
      };
    };
  };
}
