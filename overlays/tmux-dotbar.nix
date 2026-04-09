final: prev: {
  tmuxPlugins = prev.tmuxPlugins // {
    dotbar = prev.tmuxPlugins.dotbar.overrideAttrs (_old: rec {
      version = "0.3.2";

      src = prev.fetchFromGitHub {
        owner = "vaaleyard";
        repo = "tmux-dotbar";
        rev = version;
        hash = "sha256-WaRKepmPqiE+W8Tm0dBc6hGiqqZP122eXjrG0rJnt0w=";
      };
    });
  };
}
