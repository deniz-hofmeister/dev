local dap = require("dap")

-- Adapters. codelldb (>= 1.11) speaks DAP over stdio; rust sessions are set up
-- by rustaceanvim, which auto-detects codelldb on PATH.
dap.adapters.codelldb = {
	type = "executable",
	command = "codelldb",
}
dap.adapters.gdb = {
	type = "executable",
	command = "gdb",
	args = { "--interpreter=dap", "--eval-command", "set print pretty on" },
}

dap.configurations.cpp = {
	{
		name = "Launch (codelldb)",
		type = "codelldb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
		end,
		cwd = "${workspaceFolder}",
	},
	{
		name = "Attach to process (codelldb)",
		type = "codelldb",
		request = "attach",
		pid = require("dap.utils").pick_process,
		cwd = "${workspaceFolder}",
	},
	{
		name = "Launch (gdb)",
		type = "gdb",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/build/", "file")
		end,
		cwd = "${workspaceFolder}",
	},
}
dap.configurations.c = dap.configurations.cpp

-- Python: adapter runs the nix-provided interpreter (ships debugpy); the
-- debuggee interpreter is resolved per session ($VIRTUAL_ENV, .venv, ...).
require("dap-python").setup(vim.fn.exepath("python3"))
require("dap-python").test_runner = "pytest"

vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapBreakpointCondition", { text = "◐", texthl = "DapBreakpointCondition" })
vim.fn.sign_define(
	"DapStopped",
	{ text = "▶", texthl = "DapStopped", numhl = "DapStopped", linehl = "DapStoppedLine" }
)
vim.fn.sign_define("DapBreakpointRejected", { text = "✗", texthl = "DapBreakpointRejected" })
vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })

-- UI: nvim-dap-view (single bottom window, sections in a winbar), including
-- inline variable values (0.12 native virtual text)
require("dap-view").setup({
	auto_toggle = true,
	winbar = {
		sections = { "scopes", "watches", "exceptions", "breakpoints", "threads", "repl", "console" },
		default_section = "scopes",
	},
	virtual_text = { enabled = true, position = "inline" },
})

local widgets = require("dap.ui.widgets")

vim.keymap.set("n", "<leader>db", dap.toggle_breakpoint, { desc = "Toggle Breakpoint" })
vim.keymap.set("n", "<leader>dB", function()
	dap.set_breakpoint(vim.fn.input("Breakpoint condition: "))
end, { desc = "Conditional Breakpoint" })
vim.keymap.set("n", "<leader>dL", function()
	dap.set_breakpoint(nil, nil, vim.fn.input("Log point message: "))
end, { desc = "Log Point" })
vim.keymap.set("n", "<leader>dx", function()
	dap.set_exception_breakpoints()
end, { desc = "Exception Breakpoints" })
vim.keymap.set("n", "<leader>dc", dap.continue, { desc = "Continue" })
vim.keymap.set("n", "<leader>dC", dap.run_to_cursor, { desc = "Run to Cursor" })
vim.keymap.set("n", "<leader>ds", dap.step_over, { desc = "Step Over" })
vim.keymap.set("n", "<leader>di", dap.step_into, { desc = "Step Into" })
vim.keymap.set("n", "<leader>do", dap.step_out, { desc = "Step Out" })
vim.keymap.set("n", "<leader>dj", dap.down, { desc = "Down Stack Frame" })
vim.keymap.set("n", "<leader>dk", dap.up, { desc = "Up Stack Frame" })
vim.keymap.set("n", "<leader>dp", dap.pause, { desc = "Pause" })
vim.keymap.set("n", "<leader>dr", "<cmd>DapViewShow repl<cr>", { desc = "Show REPL" })
vim.keymap.set("n", "<leader>dl", dap.run_last, { desc = "Run Last" })
vim.keymap.set("n", "<leader>dt", dap.terminate, { desc = "Terminate" })
vim.keymap.set({ "n", "x" }, "<leader>dw", widgets.hover, { desc = "Inspect Value" })
vim.keymap.set("n", "<leader>du", "<cmd>DapViewToggle<cr>", { desc = "Toggle DAP View" })
vim.keymap.set({ "n", "v" }, "<leader>de", "<cmd>DapViewWatch<cr>", { desc = "Add Watch" })
vim.keymap.set("n", "<leader>df", "<cmd>DapViewJump scopes<cr>", { desc = "Focus Scopes" })
