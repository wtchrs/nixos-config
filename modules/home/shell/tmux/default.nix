{ pkgs, ... }:

{
  imports = [ ./shell-integration.nix ];

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
          set -g @tmux-dotbar-fg "#616e88"
          set -g @tmux-dotbar-fg-current "#d8dee9"
          set -g @tmux-dotbar-fg-session "#8fbcbb"
          set -g @tmux-dotbar-fg-prefix "#81a1c1"

          set -g @tmux-dotbar-right true
          set -g @tmux-dotbar-rounded false
          set -g @tmux-dotbar-ssh-icon-only true
          set -g @tmux-dotbar-show-maximized-icon-for-all-tabs true
          set -g @tmux-dotbar-session-text " #H:#S "
        '';
      }

      {
        plugin = vim-tmux-navigator;
        extraConfig = ''
          bind C-h send-keys C-h
          bind C-l send-keys C-l
          bind C-k send-keys C-k
          bind C-j send-keys C-j
        '';
      }
      yank
    ];

    extraConfig = ''
      set-option -g renumber-windows on

      bind C-s new-session -c "#{pane_current_path}"
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

      # Use Meta/Alt + hjkl keys to resize panes
      bind -r M-h resize-pane -L 4
      bind -r M-l resize-pane -R 4
      bind -r M-k resize-pane -U 2
      bind -r M-j resize-pane -D 2

      # Shift hl to switch windows
      bind H previous-window
      bind L next-window

      # Popups
      bind -n M-t display-popup -d "#{pane_current_path}" -w90% -h80% -E "$SHELL"
      bind -n M-g display-popup -d "#{pane_current_path}" -w90% -h80% -E \
        'zsh -lc "export GPG_TTY=$(tty); gpg-connect-agent updatestartuptty /bye >/dev/null; exec lazygit"'
      bind -n M-e display-popup -w90% -h80% -E btop

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

      set -g extended-keys always
      set -g extended-keys-format csi-u
      set -as terminal-features ',xterm*:extkeys'

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
