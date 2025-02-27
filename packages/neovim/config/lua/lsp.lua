local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.clangd.setup({ capabilities = capabilities })
lspconfig.pyright.setup({ capabilities = capabilities })
lspconfig.svelte.setup({ capabilities = capabilities })

local configs = require("lspconfig.configs")

-- Custom diagnostic configuration
local colors = {
	error = vim.api.nvim_get_hl(0, { name = "DiagnosticError" }).fg,
	warn = vim.api.nvim_get_hl(0, { name = "DiagnosticWarn" }).fg,
	info = vim.api.nvim_get_hl(0, { name = "DiagnosticInfo" }).fg,
	hint = vim.api.nvim_get_hl(0, { name = "DiagnosticHint" }).fg,
}

vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = colors.error, bg = "none" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = colors.warn, bg = "none" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = colors.info, bg = "none" })
vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = colors.hint, bg = "none" })

vim.diagnostic.config({
	virtual_text = {
		prefix = function(diagnostic)
			local icons = {
				[vim.diagnostic.severity.ERROR] = "● ",
				[vim.diagnostic.severity.WARN] = "▲ ",
				[vim.diagnostic.severity.INFO] = "◆ ",
				[vim.diagnostic.severity.HINT] = "◇ ",
			}
			return icons[diagnostic.severity]
		end,
		format = function(_)
			return ""
		end,
		highlight = "None",
		spacing = 1,
	},
})

require("lsp_lines").setup()