-- nvim-treesitter 1.0+ uses Neovim's built-in treesitter
-- Parsers are installed via Nix, highlighting is automatic
vim.api.nvim_create_autocmd("FileType", {
  callback = function()
    pcall(vim.treesitter.start)
  end,
})
