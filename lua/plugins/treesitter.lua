-- treesitter setup (better syntax highlighting and code navigation)
return {
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		event = { "BufReadPost", "BufNewFile" },
		config = function()
			require("nvim-treesitter.configs").setup({
				-- list of language parsers to install
				ensure_installed = {
					"lua",
					"vim",
					"vimdoc",
					"svelte",
					"typescript",
					"javascript",
					"html",
					"css",
					"cpp",
					"c",
					"python",
				},

				-- install parsers synchronously (only for ensure_installed)
				sync_install = false,

				-- automatically install missing parsers when entering buffer
				auto_install = true,

				highlight = {
					enable = true,
					additional_vim_regex_highlighting = false,
				},

				-- indentation based on treesitter
				indent = { enable = true },

				-- better text selection
				incremental_selection = {
					enable = true,
					keymaps = {
						init_selection = "<CR>",
						node_incremental = "<CR>",
						scope_incremental = "<S-CR>",
						node_decremental = "<BS>",
					},
				},
			})
		end,
	},
}
