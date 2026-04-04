{ pkgs, inputs, ... }:

let
  open-ghostty-cwd-script = builtins.readFile ./scripts/niri-open-ghostty-cwd.sh;
  open-ghostty-cwd-bin = pkgs.writeShellScriptBin "niri-open-ghostty-cwd" open-ghostty-cwd-script;
in
{
  home.packages = [ open-ghostty-cwd-bin ];

  imports = [
    inputs.niri.homeModules.niri
    ./config/input.nix
    ./config/outputs.nix
    ./config/environments.nix
    ./config/autostarts.nix
    ./config/layout.nix
    ./config/animations.nix
    ./config/rules.nix
    ./config/keybinds.nix
  ];

  programs.niri = {
    enable = true;
    package = pkgs.niri-unstable;

    settings = {
      prefer-no-csd = true;
      screenshot-path = "~/Pictures/Screenshots/Screenshot from %Y-%m-%d %H-%M-%S.png";
    };
  };
}
