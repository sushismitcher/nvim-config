-- telescope setup (fuzzy finder)
return {
	{
		"nvim-telescope/telescope.nvim",
		dependencies = {
			"nvim-lua/plenary.nvim", -- required dependency
			{ "nvim-telescope/telescope-fzf-native.nvim", build = "make" }, -- better performance
		},
		config = function()
			local telescope = require("telescope")
			local actions = require("telescope.actions")

			telescope.setup({
				defaults = {
					path_display = { "truncate" },
					mappings = {
						i = {
							["<C-k>"] = actions.move_selection_previous, -- move up in search results
							["<C-j>"] = actions.move_selection_next, -- move down in search results
							["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist, -- send to quickfix
						},
					},
				},
				extensions = {
					fzf = {
						fuzzy = true, -- false will only do exact matching
						override_generic_sorter = true, -- override the generic sorter
						override_file_sorter = true, -- override the file sorter
						case_mode = "smart_case", -- or "ignore_case" or "respect_case"
					},
				},
			})

			-- load telescope extensions
			telescope.load_extension("fzf")

			-- set keymaps
			local keymap = vim.keymap
			keymap.set("n", "<leader>p", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
			keymap.set("n", "<leader>f", "<cmd>Telescope live_grep<cr>", { desc = "Find text" })
			keymap.set("n", "<leader>b", "<cmd>Telescope buffers<cr>", { desc = "Find buffers" })
			keymap.set("n", "<leader>h", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
		end,
	},
}
