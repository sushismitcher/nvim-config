-- harpoon: teleportation device for cognitive minimalists
return {
	{
		"ThePrimeagen/harpoon",
		branch = "harpoon2", -- v2 = superior evolution
		dependencies = { "nvim-lua/plenary.nvim" },
		config = function()
			local harpoon = require("harpoon")

			-- minimalist config—no bloat, just teleportation
			harpoon:setup({
				settings = {
					save_on_toggle = true, -- persist ur quantum entanglements
					save_on_change = true,
					sync_on_ui_close = true, -- retain sanity between sessions
				},
			})
			hooks = {
				before_navigate = function()
					vim.cmd("silent! update") -- save before jumping between files
				end,
			}

			-- actual galaxy brain keymaps
			vim.keymap.set("n", "<leader>a", function()
				harpoon:list():add()
			end, { desc = "Harpoon mark file" })
			vim.keymap.set("n", "<leader>e", function()
				harpoon.ui:toggle_quick_menu(harpoon:list())
			end, { desc = "Harpoon menu" })

			-- navigate marked files like ur playing piano
			vim.keymap.set("n", "<leader>s", function()
				harpoon:list():select(1)
			end, { desc = "Harpoon file 1" })
			vim.keymap.set("n", "<leader>d", function()
				harpoon:list():select(2)
			end, { desc = "Harpoon file 2" })
			vim.keymap.set("n", "<leader>c", function()
				harpoon:list():select(3)
			end, { desc = "Harpoon file 3" })
			vim.keymap.set("n", "<leader>v", function()
				harpoon:list():select(4)
			end, { desc = "Harpoon file 4" })
		end,
	},
}
