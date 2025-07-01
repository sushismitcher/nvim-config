return {
	{
		"tikhomirov/vim-glsl",
		event = { "BufReadPre", "BufNewFile" },
		init = function()
			-- file associations for common shader extensions
			vim.g.glsl_file_extensions = "*.glsl,*.vert,*.frag,*.geom,*.comp"
		end,
	},

	-- treesitter grammar for glsl
	{
		"nvim-treesitter/nvim-treesitter",
		opts = {
			ensure_installed = {
				-- add glsl to ur existing list
				"glsl",
			},
		},
	},
}
