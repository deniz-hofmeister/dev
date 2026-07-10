local telescope = require("telescope")
telescope.setup({
	pickers = {
		oldfiles = {
			cwd_only = true,
		},
	},
})

telescope.load_extension("fzf")

local builtin = require("telescope.builtin")
vim.keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Find files" })
vim.keymap.set("n", "<leader>fg", builtin.live_grep, { desc = "Live grep" })
vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "List buffers" })
vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Search help tags" })
vim.keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Recent files" })
vim.keymap.set("n", "<leader>fd", builtin.diagnostics, { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>fs", builtin.lsp_document_symbols, { desc = "Document symbols" })
vim.keymap.set("n", "<leader>fk", builtin.keymaps, { desc = "Search keymaps" })
vim.keymap.set("n", "<leader>f.", builtin.resume, { desc = "Resume last picker" })
vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Grep word under cursor" })
vim.keymap.set("n", "<leader>fS", builtin.lsp_dynamic_workspace_symbols, { desc = "Workspace symbols" })
