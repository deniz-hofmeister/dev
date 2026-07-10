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
