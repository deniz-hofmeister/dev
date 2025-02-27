require("catppuccin").setup({
	flavour = "macchiato",
	transparent_background = true,
})

-- Setup catppuccin colors for DAP
local colors = require("catppuccin.palettes").get_palette()
vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.red })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.blue })
vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.green })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = colors.surface1 })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = colors.mauve })