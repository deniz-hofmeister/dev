local telescope = require("telescope")
telescope.setup({
	pickers = {
		oldfiles = {
			cwd_only = true,
		},
	},
})

telescope.load_extension("fzf")