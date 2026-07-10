-- Defaults already cover sources (lsp/path/snippets/buffer), native vim.snippet
-- expansion with friendly-snippets from the runtimepath, and the Rust fuzzy
-- matcher (prebuilt by nixpkgs).
require("blink.cmp").setup({
	-- 'enter' preset: <CR> accepts, <C-space> menu/docs, <C-e> cancel,
	-- <C-n>/<C-p> select, <C-b>/<C-f> scroll docs, <Tab>/<S-Tab> snippet jumps
	keymap = { preset = "enter" },
	completion = {
		documentation = { auto_show = true, auto_show_delay_ms = 200 },
	},
	signature = { enabled = true },
})
