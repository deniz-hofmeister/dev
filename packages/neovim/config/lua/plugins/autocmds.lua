-- Text yank highlight
vim.api.nvim_create_autocmd("TextYankPost", {
	group = vim.api.nvim_create_augroup("highlight_yank", {}),
	callback = function()
		vim.highlight.on_yank({ timeout = 100 })
	end,
})

-- XML file type detection
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
	pattern = { "*.xacro", "*.urdf" },
	callback = function()
		vim.bo.filetype = "xml"
	end,
})