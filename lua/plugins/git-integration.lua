-- git integration that doesn't suck
return {
	-- gitsigns: git hunks + blame in the gutter (the essentials)
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		config = function()
			require("gitsigns").setup({
				signs = {
					add = { text = "+" },
					change = { text = "~" },
					delete = { text = "_" },
					topdelete = { text = "‾" },
					changedelete = { text = "~" },
				},
				current_line_blame = false, -- toggle this manually
				current_line_blame_opts = {
					virt_text = true,
					virt_text_pos = "eol",
					delay = 300,
				},
				preview_config = {
					border = "rounded",
				},
			})

			-- keymaps for hunk navigation + staging
			local gs = require("gitsigns")
			vim.keymap.set("n", "]c", function()
				if vim.wo.diff then
					return "]c"
				end
				vim.schedule(function()
					gs.next_hunk()
				end)
				return "<Ignore>"
			end, { expr = true, desc = "Next hunk" })

			vim.keymap.set("n", "[c", function()
				if vim.wo.diff then
					return "[c"
				end
				vim.schedule(function()
					gs.prev_hunk()
				end)
				return "<Ignore>"
			end, { expr = true, desc = "Prev hunk" })

			-- git operations
			vim.keymap.set("n", "<leader>hs", gs.stage_hunk, { desc = "Stage hunk" })
			vim.keymap.set("n", "<leader>hr", gs.reset_hunk, { desc = "Reset hunk" })
			vim.keymap.set("v", "<leader>hs", function()
				gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "Stage hunk" })
			vim.keymap.set("v", "<leader>hr", function()
				gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") })
			end, { desc = "Reset hunk" })

			vim.keymap.set("n", "<leader>hS", gs.stage_buffer, { desc = "Stage buffer" })
			vim.keymap.set("n", "<leader>hu", gs.undo_stage_hunk, { desc = "Undo stage hunk" })
			vim.keymap.set("n", "<leader>hR", gs.reset_buffer, { desc = "Reset buffer" })
			vim.keymap.set("n", "<leader>hp", gs.preview_hunk, { desc = "Preview hunk" })
			vim.keymap.set("n", "<leader>hb", function()
				gs.blame_line({ full = true })
			end, { desc = "Blame line" })
			vim.keymap.set("n", "<leader>tb", gs.toggle_current_line_blame, { desc = "Toggle git blame" })
			vim.keymap.set("n", "<leader>hd", gs.diffthis, { desc = "Diff this" })
		end,
	},

	-- lazygit integration: the terminal ui that's actually good
	{
		"kdheepak/lazygit.nvim",
		lazy = true,
		cmd = {
			"LazyGit",
			"LazyGitConfig",
			"LazyGitCurrentFile",
			"LazyGitFilter",
			"LazyGitFilterCurrentFile",
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
		},
		config = function()
			vim.keymap.set("n", "<leader>gg", "<cmd>LazyGit<cr>", { desc = "LazyGit" })
		end,
	},

	-- fugitive: for when u need the full git kitchen sink
	{
		"tpope/vim-fugitive",
		cmd = {
			"G",
			"Git",
			"Gdiffsplit",
			"Gread",
			"Gwrite",
			"Ggrep",
			"GMove",
			"GDelete",
			"GBrowse",
		},
		config = function()
			vim.keymap.set("n", "<leader>G", "<cmd>Git<cr>", { desc = "Git status" })
			vim.keymap.set("n", "<leader>gd", "<cmd>Gdiffsplit<cr>", { desc = "Git diff" })
		end,
	},
}
