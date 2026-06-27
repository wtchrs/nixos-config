_:

{
  programs.niri.settings.layout = {
    gaps = 10;

    struts = {
      top = 10;
      bottom = 10;
      left = 10;
      right = 10;
    };

    center-focused-column = "always";

    preset-column-widths = [
      { proportion = 0.33333; }
      { proportion = 0.5; }
      { proportion = 0.75; }
      { proportion = 1.0; }
    ];

    preset-window-heights = [
      { proportion = 0.33333; }
      { proportion = 0.5; }
      { proportion = 0.66667; }
      { proportion = 1.0; }
    ];

    default-column-width = {
      proportion = 0.5;
    };

    background-color = "transparent";

    focus-ring = {
      enable = false;
    };

    border = {
      enable = true;
      width = 1.5;

      active.gradient = {
        from = "#33ccffee";
        to = "#00ff99ee";
        angle = 45;
        relative-to = "workspace-view";
      };

      inactive.color = "#595959aa";
      urgent.color = "#9b0000";
    };

    shadow = {
      enable = true;
      softness = 5;
      spread = 1;
      offset = {
        x = 0;
        y = 0;
      };
      color = "#0007";
    };
  };
}
