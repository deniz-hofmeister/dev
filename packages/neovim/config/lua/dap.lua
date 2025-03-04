local dap = require("dap")

dap.adapters.lldb = {
	type = "executable",
	command = vim.fn.exepath("lldb-dap"),
	name = "lldb",
}

dap.adapters.cppdbg = {
	id = "cppdbg",
	type = "executable",
	command = vim.fn.exepath("OpenDebugAD7"),
}

dap.configurations.cpp = {
	{
		name = "Launch file",
		type = "cppdbg",
		request = "launch",
		program = function()
			return vim.fn.input("Path to executable: ", vim.fn.getcwd() .. "/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = true,
		setupCommands = {
			{
				text = "-enable-pretty-printing",
				description = "enable pretty printing",
				ignoreFailures = false,
			},
		},
	},
}

-- Share configurations with C
dap.configurations.c = dap.configurations.cpp

-- DAP sign configuration
vim.fn.sign_define("DapBreakpoint", { text = "", texthl = "DapBreakpoint" })
vim.fn.sign_define("DapStopped", { text = "", texthl = "DapStopped", numhl = "DapStopped", linehl = "DapStoppedLine" })
vim.fn.sign_define("DapBreakpointRejected", {
	text = "",
	texthl = "DapBreakpointRejected",
	linehl = "DapBreakpointRejected",
	numhl = "DapBreakpointRejected",
})
vim.fn.sign_define("DapLogPoint", { text = "", texthl = "DapLogPoint" })

-- DAP UI configuration
local dapui = require("dapui")

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

-- DAP Virtual Text
require("nvim-dap-virtual-text").setup({
	virt_text_pos = "eol",
	virt_text_win_col = 60,
	highlight_new_as_changed = true,
})

