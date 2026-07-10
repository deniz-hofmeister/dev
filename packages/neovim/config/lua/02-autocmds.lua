-- Text yank highlight
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", {}),
	callback = function()
		vim.hl.on_yank({ timeout = 100 })
	end,
})

-- XML file type detection
vim.filetype.add({
	extension = {
		xacro = "xml",
		urdf = "xml",
	},
})
