_:

{
  programs.niri.settings = {
    layer-rules = [
      {
        matches = [
          # DMS's wallpaper uses Quickshell's default namespace.
          { namespace = "^quickshell$"; }
        ];
        place-within-backdrop = true;
      }
    ];

    window-rules = [
      {
        geometry-corner-radius =
          let
            r = 4.0;
          in
          {
            top-left = r;
            top-right = r;
            bottom-right = r;
            bottom-left = r;
          };

        clip-to-geometry = true;
        draw-border-with-background = false;
      }

      {
        matches = [
          {
            app-id = "^(firefox|zen)$";
            title = "^Picture-in-Picture$";
          }
        ];
        open-floating = true;
      }
    ];
  };
}
