{ pkgs, neovim }:

let
  externalTools = pkgs.runCommand "neovim-external-tools" { } ''
    mkdir -p "$out/bin"
    for tool in git gcc make cmake nil stylua statix pyright-langserver \
      dlv codelldb js-debug-adapter jdtls javac rg fd xxd tree-sitter; do
      cp ${pkgs.coreutils}/bin/true "$out/bin/$tool"
    done
  '';
in
{
  neovim-tools = pkgs.runCommand "neovim-tools-check" { } ''
    for mode in bundled external; do
      export HOME="$TMPDIR/$mode/home"
      export XDG_DATA_HOME="$TMPDIR/$mode/data"
      export XDG_CACHE_HOME="$TMPDIR/$mode/cache"
      export XDG_STATE_HOME="$TMPDIR/$mode/state"
      export XDG_CONFIG_HOME="$TMPDIR/$mode/config"
      export TOOLS_PARENT_XDG_CONFIG_HOME="$XDG_CONFIG_HOME"
      export PATH="${pkgs.coreutils}/bin"
      unset JAVA_HOME TOOLS_EXTERNAL_BIN
      mkdir -p "$HOME"

      if [ "$mode" = external ]; then
        export TOOLS_EXTERNAL_BIN="${externalTools}/bin"
        export PATH="$TOOLS_EXTERNAL_BIN:$PATH"
      fi

      timeout 90s ${neovim}/bin/nvim --headless -i NONE \
        '+lua dofile("${../tests/tools.lua}")'
    done

    timeout 30s ${neovim}/bin/nvim -l ${../tests/script-mode.lua}
    touch "$out"
  '';

  neovim-java = pkgs.runCommand "neovim-java-check" { } ''
    export HOME="$TMPDIR/home"
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME"

    timeout 60s ${neovim}/bin/nvim --headless -i NONE \
      '+lua dofile("${../tests/java.lua}")'
    touch "$out"
  '';

  neovim-lintinfo = pkgs.runCommand "neovim-lintinfo-check" { } ''
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_STATE_HOME="$TMPDIR/state"
    export NVIM_LOG_FILE="$TMPDIR/nvim.log"
    export LINTINFO_RUNTIME="${../local/lintinfo.nvim}"

    timeout 30s ${pkgs.neovim-unwrapped}/bin/nvim --headless -u NONE -i NONE \
      '+lua dofile("${../tests/lintinfo.lua}")'
    touch "$out"
  '';

  neovim-treesitter = pkgs.runCommand "neovim-treesitter-check" { } ''
    export HOME="$TMPDIR/home"
    export XDG_DATA_HOME="$TMPDIR/data"
    export XDG_CACHE_HOME="$TMPDIR/cache"
    export XDG_STATE_HOME="$TMPDIR/state"
    mkdir -p "$HOME"

    timeout 30s ${neovim}/bin/nvim --headless -i NONE \
      '+lua dofile("${../tests/treesitter.lua}")'
    touch "$out"
  '';
}
