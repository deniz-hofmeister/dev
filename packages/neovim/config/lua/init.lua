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
		{ name = "copilot" },
		{ name = "nvim_lsp" },
		{ name = "luasnip" },
	}, {
		{ name = "buffer" },
	}),
})

local wk = require("which-key")
wk.setup({
	prefix = "<leader>",
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
vim.keymap.set("n", "<leader>e", ":Neotree<CR>", { noremap = true, silent = true })

vim.keymap.set("n", "<leader>g", "<nop>", { desc = "Git" })
vim.keymap.set("n", "<leader>gg", ":Git<CR>", { desc = "Fugitive" }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gd", ":Gdiffsplit<CR>", { desc = "Diff Split" }, { noremap = true, silent = true })
vim.keymap.set(
	"n",
	"<leader>ghh",
	":Gitsigns preview_hunk_inline<CR>",
	{ desc = "Hunk Change Preview" },
	{ noremap = true, silent = true }
)
vim.keymap.set("n", "<leader>ghn", ":Gitsigns next_hunk<CR>", { desc = "Next Hunk" }, { noremap = true, silent = true })
vim.keymap.set(
	"n",
	"<leader>ghp",
	":Gitsigns prev_hunk<CR>",
	{ desc = "Previous Hunk" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"<leader>ghr",
	":Gitsigns reset_hunk<CR>",
	{ desc = "Reset Hunk" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"ghh",
	":Gitsigns preview_hunk_inline<CR>",
	{ desc = "Hunk Change Preview" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"ghn",
	":Gitsigns next_hunk<CR>:Gitsigns preview_hunk_inline<CR>",
	{ desc = "Next Hunk" },
	{ noremap = true, silent = true }
)
vim.keymap.set(
	"n",
	"ghp",
	":Gitsigns prev_hunk<CR>:Gitsigns preview_hunk_inline<CR>",
	{ desc = "Previous Hunk" },
	{ noremap = true, silent = true }
)

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
local opts = { noremap = true, silent = true }

lspconfig.clangd.setup({ capabilities = capabilities })
lspconfig.pyright.setup({ capabilities = capabilities })
lspconfig.svelte.setup({ capabilities = capabilities })

local configs = require("lspconfig.configs")

if not configs.hofmeister_lsp then
	configs.hofmeister_lsp = {
		default_config = {
			cmd = { "/home/dev/repos/lsp/target/release/lsp" }, -- Path to your LSP server
			root_dir = lspconfig.util.root_pattern("Cargo.toml", ".git"), -- Root directory
			filetypes = { "rust" }, -- Filetypes to attach the LSP to
			settings = {}, -- Additional settings if needed
		},
	}
end

lspconfig.hofmeister_lsp.setup({
	capabilities = capabilities,
})

vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "gr", vim.lsp.buf.references, {})

vim.keymap.set("n", "<leader>c", "<nop>", { desc = "Code Actions" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code Action" })
vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))

vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define(
	"DapStopped",
	{ text = "", texthl = "DapStopped", numhl = "DapStopped", linehl = "DapStoppedLine" }
)
vim.fn.sign_define(
	"DapBreakpointRejected",
	{
		text = "",
		texthl = "DapBreakpointRejected",
		linehl = "DapBreakpointRejected",
		numhl = "DapBreakpointRejected",
	}
)
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

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>f", "<nop>", { desc = "Find" })
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "List buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })

local dap = require("dap")

dap.adapters.lldb = {
	type = "executable",
	command = vim.fn.exepath("lldb-dap"),
	name = "lldb",
}

vim.keymap.set("n", "<leader>d", "<nop>", { desc = "Debug" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })

vim.keymap.set("n", "<leader>r", "<nop>", { desc = "Rust" })
vim.keymap.set("n", "<leader>rd", "<cmd>RustLsp debuggables<cr>", { silent = true, desc = "Debug" })
vim.keymap.set("n", "<leader>rr", "<cmd>RustLsp runnables<cr>", { silent = true, desc = "Run" })
vim.keymap.set("n", "<leader>rc", "<cmd>RustLsp openCargo<cr>", { silent = true, desc = "Open Cargo.toml" })
vim.keymap.set("n", "<leader>ra", "<cmd>RustLsp codeAction<cr>", { silent = true, desc = "Code Action" })
vim.keymap.set("n", "<leader>re", "<cmd>RustLsp explainError<cr>", { silent = true, desc = "Explain Error" })
vim.keymap.set("n", "<leader>rx", "<cmd>RustLsp renderDiagnostic<cr>", { silent = true, desc = "Render Diagnostic" })

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

vim.keymap.set("n", "<leader>x", "<nop>", { desc = "Trouble" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
vim.keymap.set("n", "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
vim.keymap.set(
	"n",
	"<leader>cl",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	{ desc = "LSP Definitions / references / ..." }
)
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List" })

require("todo-comments").setup()

require("neotest").setup({
	adapters = {
		require("rustaceanvim.neotest"),
	},
})
vim.keymap.set("n", "<leader>rt", "<nop>", { desc = "Test" })
vim.keymap.set("n", "<leader>rtp", function()
	require("neotest").run.run(vim.fn.getcwd())
end, { desc = "Run all tests in project" })

vim.keymap.set("n", "<leader>rtf", function()
	require("neotest").run.run(vim.fn.expand("%"))
end, { desc = "Run all tests in current file" })

vim.keymap.set("n", "<leader>rtn", function()
	require("neotest").run.run()
end, { desc = "Run nearest test" })

vim.keymap.set("n", "<leader>rtd", function()
	require("neotest").run.run({ strategy = "dap" })
end, { desc = "Debug nearest test" })

vim.keymap.set("n", "<leader>rts", function()
	require("neotest").run.stop()
end, { desc = "Stop all tests" })

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

vim.keymap.set("n", "<leader>du", dapui.toggle, { desc = "Toggle DAP UI" })
vim.keymap.set("n", "<leader>df", function()
	for _, win in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
		local buf = vim.api.nvim_win_get_buf(win)
		local buf_name = vim.api.nvim_buf_get_name(buf)
		if buf_name:match("DAP Scopes") then
			vim.api.nvim_set_current_win(win)
			break
		end
	end
end, { desc = "Focus on Scopes" })

require("markview").setup()

-- Keymaps for markview
vim.keymap.set("n", "<leader>m", "<nop>", { desc = "Markview" })
vim.keymap.set("n", "<leader>mm", "<cmd>Markview toggleAll<cr>", { desc = "Toggle Markview for all buffers" })
vim.keymap.set("n", "<leader>me", "<cmd>Markview enableAll<cr>", { desc = "Enable Markview for all buffers" })
vim.keymap.set("n", "<leader>md", "<cmd>Markview disableAll<cr>", { desc = "Disable Markview for all buffers" })
vim.keymap.set("n", "<leader>mt", "<cmd>Markview toggle<cr>", { desc = "Toggle Markview for current buffer" })
vim.keymap.set(
	"n",
	"<leader>ms",
	"<cmd>Markview splitToggle<cr>",
	{ desc = "Toggle Markview split for current buffer" }
)
vim.keymap.set("n", "<leader>mh", "<cmd>Markview hybridToggle<cr>", { desc = "Toggle Hybrid Mode" })

require("copilot").setup({
	suggestion = { enabled = false },
	panel = { enabled = false },
})

require("copilot_cmp").setup()

require("CopilotChat").setup()
vim.keymap.set("v", "gC", function()
	require("CopilotChat").open({
		context = { "buffer", "files" },
	})
end, { desc = "Open Copilot Chat with selected context" })

vim.keymap.set("n", "<leader>cc", function()
	require("CopilotChat").open({
		context = { "buffer", "files" },
	})
end, { desc = "Open Copilot Chat" })

vim.keymap.set("n", "<leader>cq", function()
	require("CopilotChat").close()
end, { desc = "Close Copilot Chat" })

require("lualine").setup({
	sections = {
		lualine_x = { "copilot", "encoding", "fileformat", "filetype" },
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

vim.keymap.set("n", "<leader>cd", require("lsp_lines").toggle, { desc = "Toggle LSP Messages" })

require("oil").setup({
	columns = {
		-- "icon",
		-- "permissions",
		-- "size",
		-- "mtime",
	},
})
vim.keymap.set("n", "<leader>o", "<cmd>Oil --float<cr>", { desc = "Oil" })
