{
  # Rules repeat and apply in order, so each rule goes in its own _children entry.
  wayland.windowManager.niri.settings._children = [
    {
      layer-rule = {
        # DMS's wallpaper uses Quickshell's default namespace.
        match._props.namespace = "^quickshell$";
        place-within-backdrop = true;
      };
    }

    {
      window-rule = {
        geometry-corner-radius = 4.0;
        clip-to-geometry = true;
        draw-border-with-background = false;
      };
    }

    {
      window-rule = {
        match._props = {
          app-id = "^(firefox|zen)$";
          title = "^Picture-in-Picture$";
        };
        open-floating = true;
      };
    }
  ];
}
