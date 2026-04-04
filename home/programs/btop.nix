_:

{
  programs.btop = {
    enable = true;
    settings = {
      color_theme = "nord";
      theme_background = false;
    };
    extraConfig = ''
      proc_sorting = "pid"
      proc_reversed = true
      proc_tree = true
      proc_gradient = false
    '';
  };
}
