_:

{
  programs.niri.settings.spawn-at-startup = [
    { argv = [ "qs" ]; }
    { argv = [ "dunst" ]; }
    { argv = [ "systemctl" "--user" "start" "hyprpolkitagent" ]; }
    { argv = [ "vesktop" ]; }
    { argv = [ "spotify" ]; }
  ];
}
