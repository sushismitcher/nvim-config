-- ui enhancements
return {
	-- which-key (helps u remember keybindings)
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			marks = true,
			registers = true,
			spelling = {
				enabled = true,
				suggestions = 20,
			},
			presets = {
				operators = true,
				motions = true,
				text_objects = true,
				windows = true,
				nav = true,
				z = true,
				g = true,
			},
		},
	},

	-- easy motion
	{
		"easymotion/vim-easymotion",
		lazy = false,
		config = function()
			-- disable default mappings
			vim.g.EasyMotion_do_mapping = 0
			vim.g.EasyMotion_smartcase = 1

			-- set up custom keymappings
			vim.keymap.set("n", ".", "<Plug>(easymotion-s2)", { desc = "Jump to 2-char pattern" })
			vim.keymap.set("n", "<Leader>t", "<Plug>(easymotion-t2)", { desc = "Jump to before 2-char pattern" })
		end,
	},

	-- commenting plugin
	{
		"terrortylor/nvim-comment",
		config = function()
			require("nvim_comment").setup({ create_mappings = false })
			vim.keymap.set({ "n", "v" }, "<leader>/", ":CommentToggle<cr>", { desc = "Toggle comment" })
		end,
	},
}
