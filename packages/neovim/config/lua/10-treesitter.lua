-- nvim-treesitter main branch: no modules, no setup(). Parsers and queries are
-- installed by nix; highlighting/folds/indent are enabled per buffer here.
-- Structural motions are buffer-local so buffers without a parser keep the
-- built-in ]] / [[ section motions.
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("treesitter_start", {}),
	callback = function(ev)
		if not pcall(vim.treesitter.start, ev.buf) then
			return
		end
		vim.wo[0][0].foldexpr = "v:lua.vim.treesitter.foldexpr()"
		vim.wo[0][0].foldmethod = "expr"
		vim.bo[ev.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"

		local move = require("nvim-treesitter-textobjects.move")
		local function goto_map(lhs, fn, query, desc)
			vim.keymap.set({ "n", "x", "o" }, lhs, function()
				move[fn](query, "textobjects")
			end, { buffer = ev.buf, desc = desc })
		end
		goto_map("]f", "goto_next_start", "@function.outer", "Next function")
		goto_map("[f", "goto_previous_start", "@function.outer", "Previous function")
		goto_map("]]", "goto_next_start", "@class.outer", "Next class")
		goto_map("[[", "goto_previous_start", "@class.outer", "Previous class")
	end,
})
