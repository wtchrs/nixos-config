return function(lazyPath)
  require("lazy").setup({
    defaults = {
      lazy = false,
    },
    dev = {
      -- reuse files from pkgs.vimPlugins.*
      -- path = "${lazyPath}",
      path = lazyPath,
      patterns = { "" },
      -- fallback to download
      fallback = true,
    },
    spec = {
      { "LazyVim/LazyVim", import = "lazyvim.plugins" },
      -- manage LSP as nix packages
      { "williamboman/mason-lspconfig.nvim", enabled = false },
      { "williamboman/mason.nvim", enabled = false },
      {
        "nvim-treesitter/nvim-treesitter",
        parser_install_dir = vim.fn.stdpath("data") .. "/nvim/parsers",
      },
      { import = "lazyvim.plugins.extras.editor.neo-tree" },
      { import = "plugins" },
    },
    checker = {
      enabled = false,
      notify = false,
    },
    ui = {
      border = "rounded",
    },
  })
end
