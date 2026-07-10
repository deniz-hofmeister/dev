require("nvim-web-devicons").setup()

require("lualine").setup({})

require("neo-tree").setup({
	close_if_last_window = false,
	enable_git_status = true,
	enable_diagnostics = true,
})

require("oil").setup({})

require("trouble").setup({
	focus = true,
})

require("todo-comments").setup()
vim.keymap.set("n", "<leader>xt", "<cmd>Trouble todo toggle<cr>", { desc = "Todos (Trouble)" })
vim.keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find Todos" })
vim.keymap.set("n", "]t", function()
	require("todo-comments").jump_next()
end, { desc = "Next Todo" })
vim.keymap.set("n", "[t", function()
	require("todo-comments").jump_prev()
end, { desc = "Previous Todo" })

require("render-markdown").setup({})

-- mini.nvim modules (mini.comment dropped: native gc since 0.10)
require("mini.surround").setup()
require("mini.hipatterns").setup()
require("mini.indentscope").setup()

local ai = require("mini.ai")
ai.setup({
	custom_textobjects = {
		f = ai.gen_spec.treesitter({ a = "@function.outer", i = "@function.inner" }),
		c = ai.gen_spec.treesitter({ a = "@class.outer", i = "@class.inner" }),
	},
})
