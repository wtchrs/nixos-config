{ lib, pkgs, ... }:

let
  plugins = with pkgs.vimPlugins; [
    lazy-nvim
    LazyVim
    bufferline-nvim
    blink-cmp
    clangd_extensions-nvim
    cmake-tools-nvim
    conform-nvim
    crates-nvim
    flash-nvim
    friendly-snippets
    gitsigns-nvim
    grug-far-nvim
    lazydev-nvim
    lualine-nvim
    neo-tree-nvim
    noice-nvim
    nord-nvim
    nui-nvim
    nvim-dap
    nvim-dap-python
    nvim-dap-ui
    nvim-dap-virtual-text
    nvim-jdtls
    nvim-lint
    nvim-lspconfig
    nvim-nio
    nvim-treesitter.withAllGrammars
    nvim-treesitter-textobjects
    nvim-ts-autotag
    # nvim-ts-context-commentstring
    nvim-web-devicons
    persistence-nvim
    plenary-nvim
    presence-nvim
    rustaceanvim
    SchemaStore-nvim
    snacks-nvim
    todo-comments-nvim
    trouble-nvim
    ts-comments-nvim
    venv-selector-nvim
    vim-startuptime
    which-key-nvim
    # {
    #   name = "LuaSnip";
    #   path = luasnip;
    # }
    {
      name = "mini.ai";
      path = mini-nvim;
    }
    # {
    #   name = "mini.bufremove";
    #   path = mini-nvim;
    # }
    # {
    #   name = "mini.comment";
    #   path = mini-nvim;
    # }
    {
      name = "mini.icons";
      path = mini-nvim;
    }
    # {
    #   name = "mini.indentscope";
    #   path = mini-nvim;
    # }
    {
      name = "mini.pairs";
      path = mini-nvim;
    }
    {
      name = "mini.surround";
      path = mini-nvim;
    }
  ];

  mkEntryFromDrv =
    drv:
    if lib.isDerivation drv then
      {
        name = "${lib.getName drv}";
        path = drv;
      }
    else
      drv;

  lazyPath = pkgs.linkFarm "lazy-plugins" (map mkEntryFromDrv plugins);
in
{
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      gcc
      tree-sitter

      lua-language-server
      stylua
      nixd # LSP for nix
      statix # Linter for nix

      ripgrep
      fd
    ];

    initLua = ''
      vim.opt.rtp:prepend("${pkgs.vimPlugins.lazy-nvim}/")
      local initLazy = require("config.lazy")
      initLazy("${lazyPath}")
    '';
  };

  # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
  xdg.configFile = {
    "nvim/after".source = ./after;
    "nvim/local".source = ./local;
    "nvim/lua".source = ./lua;
  };
}
