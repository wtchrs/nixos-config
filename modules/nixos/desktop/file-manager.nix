{
  pkgs,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    nautilus
  ];

  services.gvfs.enable = true;

  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };
}
