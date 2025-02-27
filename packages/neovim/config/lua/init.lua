local cmp = require("cmp")
local luasnip = require("luasnip")

cmp.setup({
	snippet = {
		expand = function(args)
			luasnip.lsp_expand(args.body)
		end,
	},
	mapping = cmp.mapping.preset.insert({
		["<C-b>"] = cmp.mapping.scroll_docs(-4),
		["<C-f>"] = cmp.mapping.scroll_docs(4),
		["<C-Space>"] = cmp.mapping.complete(),
		["<C-e>"] = cmp.mapping.abort(),
		["<CR>"] = cmp.mapping.confirm({ select = true }),
	}),
	sources = cmp.config.sources({
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
})

require("catppuccin").setup({
	flavour = "macchiato",
	transparent_background = true,
})

require("mini.surround").setup()
require("mini.comment").setup()
require("mini.ai").setup()
require("mini.hipatterns").setup()
require("mini.indentscope").setup()

require("noice").setup()

require("neo-tree").setup()

require("conform").setup({
	formatters_by_ft = {
		lua = { "stylua" },
		python = { "isort", "black" },
		javascript = { "prettierd", "prettier" },
		rust = {
			"rustfmt",
			extra_args = function()
				local config_path = vim.fn.getcwd() .. "/rustfmt.toml"
				if vim.fn.filereadable(config_path) == 1 then
					return { "--config-path", vim.fn.getcwd(), "--unstable-features" }
				else
					return { "--unstable-features" }
				end
			end,
		},
		nix = { "nixfmt" },
		xml = { "xmlformat" },
		["xacro"] = { "xmlformat" },
		["urdf"] = { "xmlformat" },
	},
	format_on_save = {
		timeout_ms = 500,
		lsp_fallback = true,
	},
})

vim.api.nvim_create_autocmd("BufWritePre", {
	pattern = "*",
	callback = function()
		require("conform").format()
	end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", {}),
	callback = function()
		vim.highlight.on_yank({ timeout = 100 })
	end,
})

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.xacro", "*.urdf" },
	callback = function()
		vim.bo.filetype = "xml"
	end,
})

local lspconfig = require("lspconfig")
local capabilities = require("cmp_nvim_lsp").default_capabilities()

lspconfig.clangd.setup({ capabilities = capabilities })
lspconfig.pyright.setup({ capabilities = capabilities })
lspconfig.svelte.setup({ capabilities = capabilities })

local configs = require("lspconfig.configs")
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define(
	"DapStopped",
	{ text = "", texthl = "DapStopped", numhl = "DapStopped", linehl = "DapStoppedLine" }
)
vim.fn.sign_define("DapBreakpointRejected", {
	text = "",
	texthl = "DapBreakpointRejected",
	linehl = "DapBreakpointRejected",
	numhl = "DapBreakpointRejected",
})
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })

local colors = require("catppuccin.palettes").get_palette()
vim.api.nvim_set_hl(0, "DapBreakpoint", { fg = colors.red })
vim.api.nvim_set_hl(0, "DapLogPoint", { fg = colors.blue })
vim.api.nvim_set_hl(0, "DapStopped", { fg = colors.green })
vim.api.nvim_set_hl(0, "DapStoppedLine", { bg = colors.surface1 })
vim.api.nvim_set_hl(0, "DapBreakpointRejected", { fg = colors.mauve })

local telescope = require("telescope")
telescope.setup({
	pickers = {
		oldfiles = {
			cwd_only = true,
		},
	},
})

telescope.load_extension("fzf")

local dap = require("dap")

dap.adapters.lldb = {
	type = "executable",
	command = vim.fn.exepath("lldb-dap"),
	name = "lldb",
}

vim.g.rustaceanvim = {
	server = {
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					-- features = {"std"},
					noDefaultFeatures = true,
				},
				checkOnSave = {
					command = "clippy",
					-- extraArgs = {"--no-default-features"},
				},
			},
		},
	},
}

require("gitsigns").setup()

require("nvim-dap-virtual-text").setup({
	virt_text_pos = "eol",
	virt_text_win_col = 60,
	highlight_new_as_changed = true,
})

require("nvim-web-devicons").setup()

require("trouble").setup({
	focus = true,
})

require("todo-comments").setup()

require("neotest").setup({
	adapters = {
		require("rustaceanvim.neotest"),
	},
})

local dap, dapui = require("dap"), require("dapui")

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.6 },
				{ id = "breakpoints", size = 0.25 },
				{ id = "watches", size = 0.15 },
			},
			size = 40,
			position = "left",
		},
	},
})

dap.listeners.after.event_initialized["dapui_config"] = function()
	local neotree_buf = vim.fn.bufnr("neo-tree")
	if neotree_buf ~= -1 and vim.api.nvim_buf_is_valid(neotree_buf) then
		vim.cmd("Neotree close")
	end
	dapui.open()
end
dap.listeners.before.event_terminated["dapui_config"] = function()
	dapui.close()
end
dap.listeners.before.event_exited["dapui_config"] = function()
	dapui.close()
end

require("markview").setup()

require("lualine").setup({
	sections = {
		lualine_x = { "encoding", "fileformat", "filetype" },
	},
})

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

require("oil").setup({
	columns = {
		-- "icon",
		-- "permissions",
		-- "size",
		-- "mtime",
	},
})
