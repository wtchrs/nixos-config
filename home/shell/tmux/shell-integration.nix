{ pkgs, ... }:
let
  tmuxDirSession = pkgs.writeShellApplication {
    name = "tmux-dir-session";
    runtimeInputs = with pkgs; [ tmux jq ];
    text = builtins.readFile ./tmux-dir-session.sh;
  };
in {
  programs.bash.shellAliases = {
    tmux = "${tmuxDirSession}/bin/tmux-dir-session";
  };
  programs.zsh.shellAliases = {
    tmux = "${tmuxDirSession}/bin/tmux-dir-session";
  };
}
