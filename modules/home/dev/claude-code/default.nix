{
  # Claude Code writes its own settings, so ~/.claude/settings.json stays
  # unmanaged and keeps pointing its statusLine command at this path.
  home.file.".claude/statusline-command.sh".source = ./statusline-command.sh;
}
