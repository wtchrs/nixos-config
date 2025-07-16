{ config, pkgs, ... }:

{
  programs.tmux = {
    enable = true;

    baseIndex = 1;
    # terminal = "screen-256color";
    escapeTime = 10;
    focusEvents = true;
    historyLimit = 50000;
    mouse = true;
    keyMode = "vi";

    plugins = with pkgs.tmuxPlugins; [
      nord
      prefix-highlight
    ];

    extraConfig = ''
      set -g default-terminal "tmux-256color"
      set -ag terminal-features ",xterm-256color:RGB"

      set -g pane-border-status bottom
      set -g pane-border-format " #P #{pane_current_command} - #{pane_current_path} "

      set -g status-interval 2
      set -g status-right-length 100

      # Key Bindings

      bind C-c new-window -c "#{pane_current_path}"

      # virtical split shortcut
      bind v   split-window -h
      bind C-v split-window -h -c "#{pane_current_path}"

      # horizontal split shortcut
      bind g   split-window -v
      bind C-g split-window -v -c "#{pane_current_path}"

      # Use hjkl keys to switch panes
      bind h select-pane -L
      bind l select-pane -R
      bind k select-pane -U
      bind j select-pane -D

      # Use Ctrl + hjkl keys to resize panes
      bind -r C-h resize-pane -L 4
      bind -r C-l resize-pane -R 4
      bind -r C-k resize-pane -U 2
      bind -r C-j resize-pane -D 2

      # Shift hl to switch windows
      bind H previous-window
      bind L next-window

      # Popups
      bind e display-popup -E -d '#{pane_current_path}' ranger
      bind C-q display-popup -E -w60% -h70% htop

      bind -T prefix q display-panes -d 0

      # move pane to window
      #bind-key C-@ choose-window 'join-pane -t "%%"'
      bind-key C-Space command-prompt -p "join pane to:" "join-pane -t '%%' -h"

      # change window order
      bind-key -n C-S-Left  swap-window -t -1 \; previous-window
      bind-key -n C-S-Right swap-window -t +1 \; next-window
    '';
  };
}
