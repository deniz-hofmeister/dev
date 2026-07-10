-- Diagnostics: signs + underline everywhere, full multi-line text on the
-- cursor line (native replacement for lsp_lines.nvim).
vim.diagnostic.config({
	severity_sort = true,
	signs = {
		text = {
			[vim.diagnostic.severity.ERROR] = "● ",
			[vim.diagnostic.severity.WARN] = "▲ ",
			[vim.diagnostic.severity.INFO] = "◆ ",
			[vim.diagnostic.severity.HINT] = "◇ ",
		},
	},
	virtual_text = false,
	virtual_lines = { current_line = true },
	float = { source = "if_many", border = "rounded" },
})

-- Toggle between cursor-line-only and all-lines diagnostics text
vim.keymap.set("n", "<leader>ad", function()
	local cfg = vim.diagnostic.config().virtual_lines
	if type(cfg) == "table" and cfg.current_line then
		vim.diagnostic.config({ virtual_lines = true })
	else
		vim.diagnostic.config({ virtual_lines = { current_line = true } })
	end
end, { desc = "Toggle diagnostic lines everywhere" })

-- Server configuration. nvim-lspconfig provides the base configs (lsp/*.lua
-- on the runtimepath); per-name vim.lsp.config() calls merge over those.
-- blink.cmp registers its capabilities on '*' automatically.

-- '*' is a lowest-precedence default: it only applies to configs without a
-- bundled lsp/<name>.lua definition (e.g. rustaceanvim's 'rust-analyzer')
vim.lsp.config("*", {
	root_markers = { ".git" },
})

vim.lsp.config("clangd", {
	cmd = { "clangd", "--completion-style=detailed" },
})

vim.lsp.config("basedpyright", {
	settings = {
		basedpyright = {
			disableOrganizeImports = true, -- ruff owns import sorting
			analysis = {
				typeCheckingMode = "standard",
				diagnosticSeverityOverrides = {
					-- covered by ruff (F401/F841); keep reportUndefinedVariable
					-- for basedpyright's auto-import quickfixes
					reportUnusedImport = "none",
					reportUnusedVariable = "none",
				},
			},
		},
	},
})

-- rust_analyzer is deliberately absent: rustaceanvim owns it (17-rust.lua)
vim.lsp.enable({
	"clangd",
	"basedpyright",
	"ruff",
	"nixd",
	"bashls",
	"dockerls",
	"yamlls",
	"marksman",
	"lemminx",
	"cmake",
	"taplo",
	"svelte",
	"ts_ls",
	"html",
	"cssls",
	"jsonls",
	"eslint",
})

vim.api.nvim_create_autocmd("LspAttach", {
	group = vim.api.nvim_create_augroup("lsp_attach", {}),
	callback = function(ev)
		local client = assert(vim.lsp.get_client_by_id(ev.data.client_id))

		-- basedpyright owns hover for python
		if client.name == "ruff" then
			client.server_capabilities.hoverProvider = false
		end

		if client:supports_method("textDocument/definition") then
			vim.keymap.set("n", "gd", vim.lsp.buf.definition, { buffer = ev.buf, desc = "Definition" })
		end
		if client:supports_method("textDocument/declaration") then
			vim.keymap.set("n", "gD", vim.lsp.buf.declaration, { buffer = ev.buf, desc = "Declaration" })
		end
		-- references: native grr (a bare gr map would delay grn/gra/gri/grt)

		if client:supports_method("textDocument/inlayHint") then
			vim.lsp.inlay_hint.enable(true, { bufnr = ev.buf })
		end
		if client:supports_method("textDocument/codeLens") then
			vim.lsp.codelens.enable(true, { bufnr = ev.buf })
		end
		if client.name == "rust-analyzer" then
			vim.lsp.on_type_formatting.enable(true, { client_id = client.id })
		end
		if client.name == "clangd" then
			-- buffer-local command created by nvim-lspconfig's clangd on_attach
			vim.keymap.set(
				"n",
				"<leader>ch",
				"<cmd>LspClangdSwitchSourceHeader<cr>",
				{ buffer = ev.buf, desc = "Switch Source/Header" }
			)
		end
	end,
})

vim.keymap.set("n", "<leader>ai", function()
	vim.lsp.inlay_hint.enable(not vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }), { bufnr = 0 })
end, { desc = "Toggle inlay hints (buffer)" })
