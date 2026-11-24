-- The wrapper always passes -u, so script mode must skip the editor config explicitly.
assert(vim.g.nvim_store_config_dir == nil, "nvim -l loaded the editor config")
assert(package.loaded["lazy"] == nil, "nvim -l loaded lazy.nvim")
print("Script mode skipped the editor config")
