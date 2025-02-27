-- Neo-tree
vim.keymap.set("n", "<leader>e", ":Neotree<CR>", { noremap = true, silent = true })

-- Git mappings
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

-- LSP mappings
vim.keymap.set("n", "gd", vim.lsp.buf.definition, {})
vim.keymap.set("n", "gr", vim.lsp.buf.references, {})
vim.keymap.set("n", "<leader>c", "<nop>", { desc = "Code Actions" })
vim.keymap.set("n", "<leader>cr", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
vim.keymap.set("n", "<leader>ca", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Code Action" })
vim.keymap.set("n", "<leader>ch", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))
vim.keymap.set("n", "<leader>cd", require("lsp_lines").toggle, { desc = "Toggle LSP Messages" })

-- Telescope mappings
vim.keymap.set("n", "<leader>f", "<nop>", { desc = "Find" })
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "List buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })

-- DAP mappings
vim.keymap.set("n", "<leader>d", "<nop>", { desc = "Debug" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dr", dap.repl.open, { desc = "Open REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
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

-- Rust mappings
vim.keymap.set("n", "<leader>r", "<nop>", { desc = "Rust" })
vim.keymap.set("n", "<leader>rd", "<cmd>RustLsp debuggables<cr>", { silent = true, desc = "Debug" })
vim.keymap.set("n", "<leader>rr", "<cmd>RustLsp runnables<cr>", { silent = true, desc = "Run" })
vim.keymap.set("n", "<leader>rc", "<cmd>RustLsp openCargo<cr>", { silent = true, desc = "Open Cargo.toml" })
vim.keymap.set("n", "<leader>ra", "<cmd>RustLsp codeAction<cr>", { silent = true, desc = "Code Action" })
vim.keymap.set("n", "<leader>re", "<cmd>RustLsp explainError<cr>", { silent = true, desc = "Explain Error" })
vim.keymap.set("n", "<leader>rx", "<cmd>RustLsp renderDiagnostic<cr>", { silent = true, desc = "Render Diagnostic" })

-- Rust test mappings
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

-- Trouble mappings
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

-- Markview mappings
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

-- Oil file manager
vim.keymap.set("n", "<leader>o", "<cmd>Oil --float<cr>", { desc = "Oil" })
