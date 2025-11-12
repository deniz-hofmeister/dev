local wk = require("which-key")
wk.setup({
	prefix = "<leader>",
})

local opts = { noremap = true, silent = true }

-- Neo-tree
vim.keymap.set("n", "<leader>e", ":Neotree<CR>", { noremap = true, silent = true })

-- Git mappings
vim.keymap.set("n", "<leader>g", "<nop>", { desc = "Git" })
vim.keymap.set("n", "<leader>gg", ":Git<CR>", { desc = "Fugitive" }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gd", ":Gdiffsplit<CR>", { desc = "Diff Split" }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<CR>", { desc = "Diffview" }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gV", "<cmd>DiffviewFileHistory<CR>", { desc = "File History" }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gb", function()
	vim.ui.input({ prompt = "Compare with branch: " }, function(branch)
		if branch and branch ~= "" then
			vim.cmd("DiffviewOpen " .. branch)
		end
	end)
end, { desc = "Compare with branch..." }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gm", function()
	vim.ui.input({ prompt = "Merge with branch: " }, function(branch)
		if branch and branch ~= "" then
			-- Perform git merge without auto-commit
			vim.fn.system("git merge --no-commit --no-ff " .. vim.fn.shellescape(branch))
			local exit_code = vim.v.shell_error

			if exit_code == 0 then
				print("Merge completed. Review changes and commit.")
			else
				print("Merge conflicts detected. Resolve in diffview.")
			end
			vim.cmd("DiffviewOpen")
		end
	end)
end, { desc = "Merge with branch..." }, { noremap = true, silent = true })
vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<CR>", { desc = "Close Diffview" }, { noremap = true, silent = true })
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
vim.keymap.set("n", "<leader>a", "<nop>", { desc = "Actions on Code" })
vim.keymap.set("n", "<leader>ar", vim.lsp.buf.rename, vim.tbl_extend("force", opts, { desc = "Rename" }))
vim.keymap.set("n", "<leader>aa", vim.lsp.buf.code_action, { buffer = bufnr, desc = "Actions" })
vim.keymap.set("n", "<leader>ah", vim.lsp.buf.hover, vim.tbl_extend("force", opts, { desc = "Hover Documentation" }))
vim.keymap.set("n", "<leader>ad", require("lsp_lines").toggle, { desc = "Toggle LSP Messages" })

-- Telescope mappings
local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>f", "<nop>", { desc = "Find" })
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "List buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })

-- DAP mappings
local dap, dapui = require("dap"), require("dapui")
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
vim.keymap.set("n", "<leader>dt", function()
	require("dap").terminate()
end, { desc = "Terminate debug session" })

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
vim.keymap.set("n", "<leader>as", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
vim.keymap.set(
	"n",
	"<leader>al",
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

-- CPP Projects Specific
vim.keymap.set("n", "<leader>c", "<nop>", { desc = "cpp" })
vim.keymap.set("n", "<leader>cb", function()
	-- Find the project root (assuming it contains a .git directory)
	local root = vim.fs.find(".git", { upward = true, type = "directory" })[1]
	if not root then
		print("Project root not found")
		return
	end
	root = vim.fs.dirname(root)

	-- Find all CMakeLists.txt files in the project
	local cmake_files = vim.fs.find("CMakeLists.txt", {
		path = root,
		type = "file",
		limit = math.huge,
	})

	if #cmake_files == 0 then
		print("No CMakeLists.txt found")
		return
	end

	-- Use the deepest CMakeLists.txt file
	local deepest_cmake = cmake_files[#cmake_files]
	local dir = vim.fs.dirname(deepest_cmake)

	-- Construct the command
	local cmd = string.format(
		"cd %s && \
    mkdir -p build && \
    cd build && \
    cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 -DCMAKE_BUILD_TYPE=DEBUG .. && \
    make && \
    cd .. && \
    if [ ! -L compile_commands.json ] && [ -f build/compile_commands.json ]; then \
        ln -sf build/compile_commands.json compile_commands.json; \
    fi",
		dir
	)

	-- Create a new buffer for output
	local buf = vim.api.nvim_create_buf(false, true)
	vim.api.nvim_buf_set_option(buf, "buftype", "nofile")
	vim.api.nvim_buf_set_option(buf, "modifiable", true)

	-- Open a new window at the bottom with a height of 7 lines
	vim.cmd("botright 7split")
	local win = vim.api.nvim_get_current_win()
	vim.api.nvim_win_set_buf(win, buf)

	-- Return to the previous window
	vim.cmd("wincmd p")

	-- Function to append lines to the buffer and scroll
	local function append_and_scroll(data)
		if data then
			local lines = vim.split(vim.trim(data), "\n")
			lines = vim.tbl_filter(function(line)
				return line ~= ""
			end, lines)
			if #lines > 0 then
				vim.api.nvim_buf_set_lines(buf, -1, -1, false, lines)
				vim.api.nvim_win_set_cursor(win, { vim.api.nvim_buf_line_count(buf), 0 })
			end
		end
	end

	-- Run the command asynchronously
	local job = vim.system({ "sh", "-c", cmd }, {
		stdout = function(_, data)
			vim.schedule(function()
				append_and_scroll(data)
			end)
		end,
		stderr = function(_, data)
			vim.schedule(function()
				append_and_scroll(data)
			end)
		end,
	}, function(obj)
		vim.schedule(function()
			if obj.code == 0 then
				append_and_scroll("CMake build completed successfully")
				print("CMake build completed successfully")

				vim.defer_fn(function()
					vim.api.nvim_buf_delete(buf, { force = true })
				end, 1000) -- Close after 1 second
			else
				append_and_scroll("CMake build failed with exit code " .. obj.code)
				print("CMake build failed with exit code " .. obj.code)
			end
		end)
	end)

	print("CMake build started in the background...")
end, { desc = "Build CMake project" })
