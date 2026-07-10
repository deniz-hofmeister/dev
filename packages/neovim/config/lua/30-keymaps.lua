-- General keymaps + which-key group labels. Feature-specific keymaps live in
-- their feature files (dap, tests, rust, cmake, git, telescope).
local wk = require("which-key")
wk.setup({})
wk.add({
	{ "<leader>a", group = "Actions on Code" },
	{ "<leader>c", group = "CMake / C++" },
	{ "<leader>d", group = "Debug" },
	{ "<leader>f", group = "Find" },
	{ "<leader>g", group = "Git" },
	{ "<leader>gh", group = "Hunks" },
	{ "<leader>m", group = "Markdown" },
	{ "<leader>r", group = "Rust" },
	{ "<leader>t", group = "Test" },
	{ "<leader>x", group = "Trouble" },
})

-- File explorers
vim.keymap.set("n", "<leader>e", "<cmd>Neotree<cr>", { desc = "File Tree" })
vim.keymap.set("n", "<leader>o", "<cmd>Oil --float<cr>", { desc = "Oil" })

-- LSP actions (native grn/gra/grr/gri/grt/gO/K remain available)
vim.keymap.set("n", "<leader>ar", vim.lsp.buf.rename, { desc = "Rename" })
vim.keymap.set({ "n", "v" }, "<leader>aa", vim.lsp.buf.code_action, { desc = "Code Actions" })
vim.keymap.set("n", "<leader>ah", vim.lsp.buf.hover, { desc = "Hover Documentation" })
vim.keymap.set("n", "<leader>as", "<cmd>Trouble symbols toggle focus=false<cr>", { desc = "Symbols" })
vim.keymap.set(
	"n",
	"<leader>al",
	"<cmd>Trouble lsp toggle focus=false win.position=right<cr>",
	{ desc = "LSP Definitions / References / ..." }
)

-- Trouble
vim.keymap.set("n", "<leader>xx", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer Diagnostics" })
vim.keymap.set("n", "<leader>xX", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
vim.keymap.set("n", "<leader>xL", "<cmd>Trouble loclist toggle<cr>", { desc = "Location List" })
vim.keymap.set("n", "<leader>xQ", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix List" })

-- Markdown rendering
vim.keymap.set("n", "<leader>mm", "<cmd>RenderMarkdown buf_toggle<cr>", { desc = "Toggle Render (buffer)" })
vim.keymap.set("n", "<leader>mM", "<cmd>RenderMarkdown toggle<cr>", { desc = "Toggle Render (global)" })
