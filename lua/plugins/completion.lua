-- completion setup (nvim-cmp & related plugins)
return {
	-- nvim-cmp (completion engine)
	{
		"hrsh7th/nvim-cmp",
		event = "InsertEnter",
		dependencies = {
			-- snippet engine
			{
				"L3MON4D3/LuaSnip",
				dependencies = {
					-- optional but recommended
					"rafamadriz/friendly-snippets",
					config = function()
						require("luasnip.loaders.from_vscode").lazy_load()
					end,
				},
			},

			-- completion sources
			"hrsh7th/cmp-nvim-lsp", -- lsp completions
			"hrsh7th/cmp-buffer", -- buffer completions
			"hrsh7th/cmp-path", -- path completions
			"saadparwaiz1/cmp_luasnip", -- snippet completions
		},
		config = function()
			local cmp = require("cmp")
			local luasnip = require("luasnip")

			-- load lsp-zero if available
			local has_lsp_zero, lsp_zero = pcall(require, "lsp-zero")
			local cmp_action = has_lsp_zero and lsp_zero.cmp_action() or nil

			cmp.setup({
				snippet = {
					expand = function(args)
						luasnip.lsp_expand(args.body)
					end,
				},
				window = {
					completion = cmp.config.window.bordered(),
					documentation = cmp.config.window.bordered(),
				},
				mapping = cmp.mapping.preset.insert({
					["<Tab>"] = cmp.mapping.confirm({ select = true }),
					["<C-u>"] = cmp.mapping.scroll_docs(-4),
					["<C-d>"] = cmp.mapping.scroll_docs(4),

					-- setup navigation if lsp_zero available
					["<C-f>"] = cmp_action and cmp_action.luasnip_jump_forward() or nil,
					["<C-b>"] = cmp_action and cmp_action.luasnip_jump_backward() or nil,

					["<C-Space>"] = cmp.mapping.complete(),
					["<C-e>"] = cmp.mapping.abort(),

					-- cycling with docs
					["<Down>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
							cmp.event:emit("complete_done", cmp.get_selected_entry())
						else
							fallback()
						end
					end, { "i", "s" }),

					["<Up>"] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
							cmp.event:emit("complete_done", cmp.get_selected_entry())
						else
							fallback()
						end
					end, { "i", "s" }),
				}),
				sources = cmp.config.sources({
					{ name = "nvim_lsp", priority = 1000 },
					{ name = "luasnip", priority = 750 },
					{ name = "buffer", priority = 500 },
					{ name = "path", priority = 250 },
				}),
				formatting = {
					fields = { "abbr", "kind", "menu" },
					format = function(entry, vim_item)
						vim_item.menu = ({
							nvim_lsp = "[LSP]",
							luasnip = "[Snippet]",
							buffer = "[Buffer]",
							path = "[Path]",
						})[entry.source.name]
						return vim_item
					end,
				},
				experimental = {
					ghost_text = true,
				},
			})
		end,
	},
}
