-- rustaceanvim is a filetype plugin: no setup() call, configured via vim.g.
-- It owns rust-analyzer (not vim.lsp.enable'd) and auto-detects codelldb on
-- PATH for DAP. This file MUST load before anything that requires a
-- rustaceanvim module (17-test.lua): the config is snapshotted at first require.
vim.g.rustaceanvim = {
	tools = {
		-- auto-detection cannot see the neotest adapter in this eager-load setup
		test_executor = "neotest",
	},
	server = {
		default_settings = {
			["rust-analyzer"] = {
				cargo = {
					noDefaultFeatures = true,
				},
				check = {
					command = "clippy",
					extraArgs = { "--no-deps" },
				},
				inlayHints = {
					closureReturnTypeHints = { enable = "always" },
					lifetimeElisionHints = { enable = "skip_trivial" },
					bindingModeHints = { enable = true },
				},
			},
		},
	},
}

-- Cargo.toml: version/feature completion, hover and update actions via the
-- in-process LSP server (the old cmp source is deprecated)
require("crates").setup({
	lsp = {
		enabled = true,
		actions = true,
		completion = true,
		hover = true,
	},
})

-- :RustLsp is a buffer-local command, only created once rust-analyzer attaches
vim.api.nvim_create_autocmd("FileType", {
	group = vim.api.nvim_create_augroup("rust_keymaps", {}),
	pattern = "rust",
	callback = function(ev)
		local function map(lhs, cmd, desc)
			vim.keymap.set("n", lhs, "<cmd>RustLsp " .. cmd .. "<cr>", { buffer = ev.buf, desc = desc })
		end
		map("<leader>rd", "debuggables", "Debug")
		map("<leader>rr", "runnables", "Run")
		map("<leader>rc", "openCargo", "Open Cargo.toml")
		map("<leader>ra", "codeAction", "Code Action")
		map("<leader>re", "explainError", "Explain Error")
		map("<leader>rx", "renderDiagnostic", "Render Diagnostic")
		map("<leader>rm", "expandMacro", "Expand Macro")
	end,
})

-- Cargo.toml: interactive crates.nvim popups (no code-action equivalent)
vim.api.nvim_create_autocmd("BufRead", {
	group = vim.api.nvim_create_augroup("crates_keymaps", {}),
	pattern = "Cargo.toml",
	callback = function(ev)
		local crates = require("crates")
		local function map(lhs, fn, desc)
			vim.keymap.set("n", lhs, fn, { buffer = ev.buf, desc = desc })
		end
		map("<leader>rv", crates.show_versions_popup, "Crate Versions")
		map("<leader>rf", crates.show_features_popup, "Crate Features")
		map("<leader>ru", crates.update_crate, "Update Crate (compatible)")
		map("<leader>rU", crates.upgrade_crate, "Upgrade Crate (latest)")
	end,
})
