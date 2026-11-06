{
  programs.atuin = {
    enable = true;

    enableBashIntegration = true;
    enableZshIntegration = true;

    settings = {
      auto_sync = true;
      sync_frequency = "5m";
      sync_address = "https://atuin.wtchrs.xyz";

      search_mode = "daemon-fuzzy";
      filter_mode = "host";

      daemon = {
        enabled = true;
        autostart = true;
      };

      store_failed = true;
    };
  };
}
