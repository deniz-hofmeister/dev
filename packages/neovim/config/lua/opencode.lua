local opencode = require("opencode")

opencode.setup({})

vim.keymap.set({ "n", "x" }, "<leader>oa", function()
	opencode.ask("@this: ", { submit = true })
end, { desc = "Opencode Ask" })

vim.keymap.set({ "n", "x" }, "<leader>ox", function()
	opencode.select()
end, { desc = "Opencode Select" })

vim.keymap.set({ "n", "t" }, "<leader>ot", function()
	opencode.toggle()
end, { desc = "Opencode Toggle" })
