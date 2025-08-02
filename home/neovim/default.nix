{ lib, pkgs, ... }:
let
  # parsers = pkgs.symlinkJoin {
  #   name = "treesitter-parsers";
  #   paths = (pkgs.vimPlugins.nvim-treesitter.withAllGrammars.dependencies);
  # };

  plugins = with pkgs.vimPlugins; [
    # LazyVim
    lazy-nvim
    LazyVim
    bufferline-nvim
    blink-cmp
    cmp-buffer
    cmp-nvim-lsp
    cmp-path
    cmp_luasnip
    conform-nvim
    dashboard-nvim
    dressing-nvim
    flash-nvim
    friendly-snippets
    gitsigns-nvim
    grug-far-nvim
    indent-blankline-nvim
    lazydev-nvim
    lualine-nvim
    neo-tree-nvim
    neoconf-nvim
    neodev-nvim
    noice-nvim
    nord-nvim
    nui-nvim
    nvim-cmp
    nvim-lint
    nvim-lspconfig
    nvim-notify
    nvim-spectre
    # nvim-treesitter
    nvim-treesitter-context
    nvim-treesitter-textobjects
    nvim-ts-autotag
    nvim-ts-context-commentstring
    nvim-web-devicons
    persistence-nvim
    plenary-nvim
    presence-nvim
    snacks-nvim
    todo-comments-nvim
    tokyonight-nvim
    trouble-nvim
    ts-comments-nvim
    vim-illuminate
    vim-startuptime
    which-key-nvim
    { name = "LuaSnip"; path = luasnip; }
    { name = "catppuccin"; path = catppuccin-nvim; }
    { name = "mini.ai"; path = mini-nvim; }
    { name = "mini.bufremove"; path = mini-nvim; }
    { name = "mini.comment"; path = mini-nvim; }
    { name = "mini.icons"; path = mini-nvim; }
    { name = "mini.indentscope"; path = mini-nvim; }
    { name = "mini.pairs"; path = mini-nvim; }
    { name = "mini.surround"; path = mini-nvim; }
  ];

  mkEntryFromDrv = drv:
    if lib.isDerivation drv then
      { name = "${lib.getName drv}"; path = drv; }
    else
      drv;

  lazyPath = pkgs.linkFarm "lazy-plugins" (builtins.map mkEntryFromDrv plugins);
in
{
  programs.neovim = {
    enable = true;

    extraPackages = with pkgs; [
      lua-language-server
      stylua
      nil # LSP for nix

      ripgrep
      fd
    ];

    extraLuaConfig = ''
      vim.opt.rtp:prepend("${pkgs.vimPlugins.lazy-nvim}/")
      local initLazy = require("config.lazy")
      initLazy("${lazyPath}")
    '';
  };

  # https://github.com/nvim-treesitter/nvim-treesitter#i-get-query-error-invalid-node-type-at-position
  # xdg.configFile."nvim/parser".source = "${parsers}/parser";

  # Normal LazyVim config here, see https://github.com/LazyVim/starter/tree/main/lua
  xdg.configFile."nvim/lua".source = ./lua;
}
