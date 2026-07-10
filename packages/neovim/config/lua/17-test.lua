local neotest = require("neotest")

neotest.setup({
	adapters = {
		require("rustaceanvim.neotest"),
		require("neotest-python")({
			dap = { justMyCode = false },
			runner = "pytest",
		}),
		require("neotest-ctest").setup({ dap_adapter = "codelldb" }),
	},
})

vim.keymap.set("n", "<leader>tn", function()
	neotest.run.run()
end, { desc = "Run Nearest Test" })
vim.keymap.set("n", "<leader>tf", function()
	neotest.run.run(vim.fn.expand("%"))
end, { desc = "Run Tests in File" })
vim.keymap.set("n", "<leader>tp", function()
	neotest.run.run(vim.fn.getcwd())
end, { desc = "Run All Tests" })
vim.keymap.set("n", "<leader>td", function()
	neotest.run.run({ strategy = "dap" })
end, { desc = "Debug Nearest Test" })
vim.keymap.set("n", "<leader>ts", function()
	neotest.run.stop()
end, { desc = "Stop Tests" })
vim.keymap.set("n", "<leader>to", function()
	neotest.output.open({ enter = true, auto_close = true })
end, { desc = "Test Output" })
vim.keymap.set("n", "<leader>tS", function()
	neotest.summary.toggle()
end, { desc = "Test Summary" })
vim.keymap.set("n", "<leader>tw", function()
	neotest.watch.toggle(vim.fn.expand("%"))
end, { desc = "Watch File" })
vim.keymap.set("n", "]n", function()
	neotest.jump.next({ status = "failed" })
end, { desc = "Next Failed Test" })
vim.keymap.set("n", "[n", function()
	neotest.jump.prev({ status = "failed" })
end, { desc = "Previous Failed Test" })
