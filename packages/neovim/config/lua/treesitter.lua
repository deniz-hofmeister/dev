local M = {}

function M.setup()
	require("nvim-treesitter.configs").setup({
		highlight = {
			enable = true,
			additional_vim_regex_highlighting = false,
		},
		indent = {
			enable = true,
		},
		ensure_installed = {}, -- Parsers are installed in the nix config
	})
end

require("treesitter").setup()
return M

