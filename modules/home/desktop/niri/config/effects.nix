{
  wayland.windowManager.niri.settings = {
    blur = {
      passes = 4;
      offset = 4.0;
      noise = 0.02;
      saturation = 1.7;
    };

    _children = [
      {
        window-rule = {
          match._props.app-id = "com.mitchellh.ghostty";
          background-effect = {
            blur = true;
            xray = false;
          };
        };
      }

      /*
        {
          window-rule = {
            match._props.app-id = "^(code|Code)$";
            background-effect = {
              blur = true;
              xray = false;
            };
          };
        }
      */
    ];
  };
}
