vim.g.mapleader = " "

vim.o.number = true
vim.o.relativenumber = true
vim.o.shiftwidth = 2
vim.o.showmode = false
vim.o.hlsearch = true
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.timeoutlen = 100
vim.o.signcolumn = "yes"
vim.opt.clipboard:prepend("unnamedplus")
vim.opt.diffopt:append("vertical")

-- Folds are provided by treesitter (see 10-treesitter.lua); start fully open
vim.o.foldlevel = 99
vim.o.foldlevelstart = 99
