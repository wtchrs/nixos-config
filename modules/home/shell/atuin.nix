{
  programs.atuin = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "http://srv-cloud-2:8888";
      search_mode = "skim";
    };
  };
}
