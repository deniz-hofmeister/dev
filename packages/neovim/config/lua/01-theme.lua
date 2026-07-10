-- catppuccin's dap integration already colors DapBreakpoint/DapBreakpointRejected;
-- only the deviations live in custom_highlights (survives :colorscheme re-apply)
require("catppuccin").setup({
	flavour = "macchiato",
	transparent_background = true,
	custom_highlights = function(colors)
		return {
			DapLogPoint = { fg = colors.blue },
			DapStopped = { fg = colors.green },
			DapStoppedLine = { bg = colors.surface1 },
		}
	end,
})

vim.cmd.colorscheme("catppuccin")
