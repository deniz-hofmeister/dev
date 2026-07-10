require("cmake-tools").setup({
	cmake_build_options = { "-j", tostring(vim.uv.available_parallelism()) },
	cmake_build_directory = "build",
	-- symlink build/compile_commands.json into nvim's cwd for clangd
	cmake_compile_commands_options = { action = "soft_link" },
	cmake_dap_configuration = {
		name = "cpp",
		type = "codelldb",
		request = "launch",
	},
})

vim.keymap.set("n", "<leader>cg", "<cmd>CMakeGenerate<cr>", { desc = "CMake Generate" })
vim.keymap.set("n", "<leader>cb", "<cmd>CMakeBuild<cr>", { desc = "CMake Build" })
vim.keymap.set("n", "<leader>cr", "<cmd>CMakeRun<cr>", { desc = "CMake Run" })
vim.keymap.set("n", "<leader>cd", "<cmd>CMakeDebug<cr>", { desc = "CMake Debug" })
vim.keymap.set("n", "<leader>cs", "<cmd>CMakeSelectLaunchTarget<cr>", { desc = "Select Launch Target" })
vim.keymap.set("n", "<leader>cS", "<cmd>CMakeSelectBuildTarget<cr>", { desc = "Select Build Target" })
vim.keymap.set("n", "<leader>ct", "<cmd>CMakeSelectBuildType<cr>", { desc = "Select Build Type" })
vim.keymap.set("n", "<leader>cx", "<cmd>CMakeStopExecutor<cr>", { desc = "Stop CMake" })
