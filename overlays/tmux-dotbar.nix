final: prev: {
  tmuxPlugins = prev.tmuxPlugins // {
    dotbar = prev.tmuxPlugins.dotbar.overrideAttrs (_old: rec {
      version = "0.3.3";

      src = prev.fetchFromGitHub {
        owner = "vaaleyard";
        repo = "tmux-dotbar";
        rev = version;
        hash = "sha256-CAKEN8Sk3t0nonV2R9df/DFTTUrVnbso0ZVGgeeGINM=";
      };
    });
  };
}
