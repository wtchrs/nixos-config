_:

{
  programs.niri.settings = {
    layer-rules = [
      {
        matches = [
          { namespace = "^quickshell:backdrop$"; }
        ];
        place-within-backdrop = true;
      }

      # 원본 KDL의 아래 규칙들은 현재 settings 트리로는 직접 옮기지 않았다.
      # layer-rule {
      #   match namespace="^quickshell:(bar|tray-menu)$"
      #   background-effect { blur true xray false }
      # }
      #
      # layer-rule {
      #   match namespace="^quickshell:launcher$"
      #   background-effect { blur true xray true }
      # }
    ];

    window-rules = [
      {
        geometry-corner-radius = let
          r = 4.0;
        in {
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

      # 원본 KDL:
      # window-rule {
      #   match app-id="com.mitchellh.ghostty"
      #   background-effect { blur true xray false }
      # }
    ];
  };
}
