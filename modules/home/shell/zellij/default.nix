{
  programs.zellij = {
    enable = true;
    extraConfig = builtins.readFile ./kdl/config.kdl;
    layouts.default = ./kdl/layout.kdl;
  };
}
