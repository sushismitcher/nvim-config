-- colorscheme setup
return {
	{
		"catppuccin/nvim",
		name = "catppuccin",
		priority = 1000, -- load this before all other plugins
		config = function()
			-- setup must happen before loading
			require("catppuccin").setup({
				flavour = "macchiato", -- latte, frappe, macchiato, mocha
				background = {
					light = "latte",
					dark = "macchiato",
				},
				transparent_background = false,
				term_colors = true,
				integrations = {
					cmp = true,
					treesitter = true,
					telescope = true,
					which_key = true,
					-- for more integrations: https://github.com/catppuccin/nvim#integrations
				},
				highlight_overrides = {
					all = function(colors)
						return {
							Comment = { fg = "#eef200" }, -- your yellow comments
						}
					end,
				},
			})

			-- load the colorscheme
			vim.cmd([[colorscheme catppuccin]])
			vim.api.nvim_set_hl(0, "Normal", { bg = "none" })
			vim.api.nvim_set_hl(0, "NormalFloat", { bg = "none" })
		end,
	},
}
