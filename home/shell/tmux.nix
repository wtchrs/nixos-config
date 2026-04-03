{ pkgs, ... }:

{
  programs.tmux = {
    enable = true;
    mouse = true;
    keyMode = "vi";
    historyLimit = 100000;
    baseIndex = 1;
    escapeTime = 10;
    focusEvents = true;
    terminal = "tmux-256color";

    plugins = with pkgs.tmuxPlugins; [
      {
        plugin = dotbar;
        extraConfig = ''
          set -g @tmux-dotbar-bg "default"
          set -g @tmux-dotbar-fg "#4c566a"
          set -g @tmux-dotbar-fg-current "#d8dee9"
          set -g @tmux-dotbar-fg-session "#8fbcbb"
          set -g @tmux-dotbar-fg-prefix "#81a1c1"

          set -g @tmux-dotbar-right true
          set -g @tmux-dotbar-ssh-icon-only true
          set -g @tmux-dotbar-show-maximized-icon-for-all-tabs true
          set -g @tmux-dotbar-session-text " #H:#S "
        '';
      }

      yank
    ];

    extraConfig = ''
      set-option -g renumber-windows on

      bind C-c new-window -c "#{pane_current_path}"

      # vertical split shortcut
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
      bind C-Space command-prompt -p "join pane to:" "join-pane -t '%%' -h"

      # change window order
      bind -n C-S-Left  swap-window -t -1 \; previous-window
      bind -n C-S-Right swap-window -t +1 \; next-window

      # Kitty Image Support
      set -gq allow-passthrough on
      set -g visual-activity off

      # terminal overrides
      set -sa terminal-overrides ",*-256color:Tc"

      # status bar
      set -g status-interval 5
      set -g status-left-length 30

      # pane border setting
      set -g pane-border-status bottom
      set -g pane-border-format ""
      set -g pane-border-style "fg=#4c566a,bg=default"
      set -g pane-active-border-style "fg=#81a1c1,bg=default"
    '';
  };
}
