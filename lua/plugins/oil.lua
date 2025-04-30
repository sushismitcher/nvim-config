-- oil.nvim - file explorer that lets u edit fs like a buffer
return {
	{
		"stevearc/oil.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
				default_file_explorer = true,
				keymaps = {
					["g?"] = "actions.show_help",
					["<CR>"] = "actions.select",
					["<C-v>"] = "actions.select_vsplit",
					["<C-s>"] = "actions.select_split",
					["<C-t>"] = "actions.select_tab",
					["-"] = "actions.parent",
					["_"] = "actions.open_cwd",
					["`"] = "actions.cd",
					["~"] = "actions.tcd",
					["g."] = "actions.toggle_hidden",
				},
				use_default_keymaps = false,
				view_options = {
					show_hidden = false,
					is_hidden_file = function(name, bufnr)
						return vim.startswith(name, ".")
					end,
				},
			})

			-- set keymaps
			vim.keymap.set("n", "-", require("oil").open, { desc = "Open file explorer" })
			vim.keymap.set("n", "<leader>k", require("oil").open, { desc = "Open file explorer" })
		end,
	},
}
