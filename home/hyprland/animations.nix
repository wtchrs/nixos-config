{ ... } :

{
  wayland.windowManager.hyprland.settings.animations = {
    enabled = true;

    bezier = [
      "overshoot, 0.05, 0.9, 0.1, 1.05"
    ];

    animation = [
      "windows, 1, 6, overshoot, slide"
      "windowsOut, 1, 6, default, slide"

      "border, 1, 10, default"
      "borderangle, 1, 8, default"

      "fade, 1, 6, default"

      "workspaces, 1, 4, overshoot, slide"

      "layersIn, 1, 4, overshoot, slide"
      "layersOut, 1, 4, default, slide"
    ];
  };
}
