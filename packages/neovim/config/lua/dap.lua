local dap = require("dap")

-- Helper function to find project root (where CMakeLists.txt is)
local function find_cmake_root()
	local current_file = vim.fn.expand("%:p")
	local current_dir = vim.fn.fnamemodify(current_file, ":h")
	local cmake_file = vim.fn.findfile("CMakeLists.txt", current_dir .. ";")

	if cmake_file ~= "" then
		return vim.fn.fnamemodify(cmake_file, ":h")
	end

	return vim.fn.getcwd() -- Fallback to current working directory
end

dap.adapters.cppdbg = {
	id = "cppdbg",
	type = "executable",
	command = vim.fn.exepath("OpenDebugAD7"),
}

dap.adapters.python = {
	type = "executable",
	command = vim.fn.exepath("python3.10"), -- Use exepath to find the full path to python3
	args = { "-m", "debugpy.adapter" },
	options = {
		env = vim.empty_dict(), -- Use empty dict to not override any env vars
		inherit_env = true, -- Inherit parent process environment
	},
}

dap.configurations.cpp = {
	{
		name = "Launch file",
		type = "cppdbg",
		request = "launch",
		program = function()
			local cmake_root = find_cmake_root()
			return vim.fn.input("Path to executable: ", cmake_root .. "/build/", "file")
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = true,
		sourceFileMap = {
			-- Map build directory source files to src directory
			[function()
				local cmake_root = find_cmake_root()
				return cmake_root .. "/build"
			end] = function()
				local cmake_root = find_cmake_root()
				return cmake_root .. "/src"
			end,
		},
		setupCommands = {
			{
				text = "-enable-pretty-printing",
				description = "enable pretty printing",
				ignoreFailures = false,
			},
			{
				-- This will be evaluated when the debug session starts
				text = function()
					local cmake_root = find_cmake_root()
					return "set substitute-path " .. cmake_root .. "/build " .. cmake_root .. "/src"
				end,
				description = "map build to src directory",
				ignoreFailures = false,
			},
		},
	},
}

-- Share configurations with C
dap.configurations.c = dap.configurations.cpp

dap.configurations.python = {
	{
		type = "python",
		request = "launch",
		name = "Launch file",
		program = "${file}",
		pythonPath = function()
			-- Detect python path
			local venv = os.getenv("VIRTUAL_ENV")
			if venv then
				return venv .. "/bin/python"
			end

			-- Check for common virtual environment paths
			local cwd = vim.fn.getcwd()
			for _, pattern in ipairs({ "/venv/", "/.venv/", "/env/", "/.env/" }) do
				local path = cwd .. pattern .. "bin/python"
				if vim.fn.executable(path) == 1 then
					return path
				end
			end

			-- Fall back to system python
			return "python"
		end,
		cwd = "${workspaceFolder}",
		stopOnEntry = false,
		justMyCode = false, -- Set to true to debug only your code
		console = "integratedTerminal",
		-- Inherit all host environment variables
		env = vim.empty_dict(),
		envFile = vim.fn.expand("~/.env"), -- Optional: load additional env vars from file
		inheritEnv = true, -- Inherit all environment from parent process
	},
}
-- DAP sign configuration
vim.fn.sign_define("DapBreakpoint", { text = "●", texthl = "DapBreakpoint" })
vim.fn.sign_define(
	"DapStopped",
	{ text = "▶", texthl = "DapStopped", numhl = "DapStopped", linehl = "DapStoppedLine" }
)
vim.fn.sign_define("DapBreakpointRejected", {
	text = "✗",
	texthl = "DapBreakpointRejected",
	linehl = "DapBreakpointRejected",
	numhl = "DapBreakpointRejected",
})
vim.fn.sign_define("DapLogPoint", { text = "◆", texthl = "DapLogPoint" })

-- DAP UI configuration
local dapui = require("dapui")

dapui.setup({
	layouts = {
		{
			elements = {
				{ id = "scopes", size = 0.7 },
				{ id = "breakpoints", size = 0.15 },
				{ id = "watches", size = 0.15 },
			},
			size = 40,
			position = "left",
		},
		{
			elements = {
				{ id = "repl", size = 0.5 },
				{ id = "console", size = 0.5 },
			},
			size = 0.25,
			position = "bottom",
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
