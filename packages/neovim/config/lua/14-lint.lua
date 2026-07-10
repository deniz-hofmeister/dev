-- Supplementary linting only: clang-tidy runs inline via clangd, ruff via its
-- LSP, clippy via rust-analyzer. cppcheck complements clang-tidy for C/C++.
local lint = require("lint")

lint.linters_by_ft = {
	c = { "cppcheck" },
	cpp = { "cppcheck" },
}

-- cppcheck reads from disk, so only lint when the file content on disk changes
vim.api.nvim_create_autocmd({ "BufReadPost", "BufWritePost" }, {
	group = vim.api.nvim_create_augroup("nvim_lint", {}),
	callback = function()
		lint.try_lint(nil, { ignore_errors = true })
	end,
})
