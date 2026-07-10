local gitsigns = require("gitsigns")
gitsigns.setup()

require("diffview").setup({
	enhanced_diff_hl = true,
	view = {
		merge_tool = {
			layout = "diff3_mixed",
		},
	},
})

vim.keymap.set("n", "<leader>gg", "<cmd>Git<cr>", { desc = "Fugitive" })
vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Diff Split" })
vim.keymap.set("n", "<leader>gv", "<cmd>DiffviewOpen<cr>", { desc = "Diffview" })
vim.keymap.set("n", "<leader>gV", "<cmd>DiffviewFileHistory<cr>", { desc = "File History" })
vim.keymap.set("n", "<leader>gq", "<cmd>DiffviewClose<cr>", { desc = "Close Diffview" })
vim.keymap.set("n", "<leader>gb", function()
	vim.ui.input({ prompt = "Compare with branch: " }, function(branch)
		if branch and branch ~= "" then
			vim.cmd("DiffviewOpen " .. branch)
		end
	end)
end, { desc = "Compare with branch..." })
vim.keymap.set("n", "<leader>gm", function()
	vim.ui.input({ prompt = "Merge with branch: " }, function(branch)
		if branch and branch ~= "" then
			vim.fn.system("git merge --no-commit --no-ff " .. vim.fn.shellescape(branch))
			if vim.v.shell_error == 0 then
				print("Merge completed. Review changes and commit.")
			else
				print("Merge conflicts detected. Resolve in diffview.")
			end
			vim.cmd("DiffviewOpen")
		end
	end)
end, { desc = "Merge with branch..." })

local function hunk_map(lhs, fn, desc)
	vim.keymap.set("n", lhs, fn, { desc = desc })
end
hunk_map("<leader>ghh", gitsigns.preview_hunk_inline, "Hunk Change Preview")
hunk_map("<leader>ghr", gitsigns.reset_hunk, "Reset Hunk")
hunk_map("<leader>ghn", function()
	gitsigns.nav_hunk("next")
end, "Next Hunk")
hunk_map("<leader>ghp", function()
	gitsigns.nav_hunk("prev")
end, "Previous Hunk")
-- nav_hunk is async: preview via its completion callback, not sequentially
hunk_map("ghh", gitsigns.preview_hunk_inline, "Hunk Change Preview")
hunk_map("ghn", function()
	gitsigns.nav_hunk("next", nil, gitsigns.preview_hunk_inline)
end, "Next Hunk")
hunk_map("ghp", function()
	gitsigns.nav_hunk("prev", nil, gitsigns.preview_hunk_inline)
end, "Previous Hunk")
