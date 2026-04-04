_:

{
  programs.niri.settings.animations = {
    slowdown = 1.5;

    workspace-switch.kind.spring = {
      damping-ratio = 0.8;
      stiffness = 800;
      epsilon = 0.0001;
    };

    window-open.kind.easing = {
      duration-ms = 150;
      curve = "ease-out-expo";
    };

    window-close.kind.easing = {
      duration-ms = 150;
      curve = "ease-out-quad";
    };

    horizontal-view-movement.kind.spring = {
      damping-ratio = 0.8;
      stiffness = 800;
      epsilon = 0.0001;
    };

    window-movement.kind.spring = {
      damping-ratio = 0.8;
      stiffness = 800;
      epsilon = 0.0001;
    };

    window-resize.kind.spring = {
      damping-ratio = 0.8;
      stiffness = 800;
      epsilon = 0.0001;
    };

    config-notification-open-close.kind.spring = {
      damping-ratio = 0.6;
      stiffness = 1000;
      epsilon = 0.001;
    };

    exit-confirmation-open-close.kind.spring = {
      damping-ratio = 0.6;
      stiffness = 500;
      epsilon = 0.01;
    };

    screenshot-ui-open.kind.easing = {
      duration-ms = 200;
      curve = "ease-out-quad";
    };

    overview-open-close.kind.spring = {
      damping-ratio = 1.0;
      stiffness = 800;
      epsilon = 0.0001;
    };

    #recent-windows-close.kind.spring = {
    #  damping-ratio = 1.0;
    #  stiffness = 800;
    #  epsilon = 0.001;
    #};
  };
}
