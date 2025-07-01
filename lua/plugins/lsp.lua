-- lsp setup w/ minimal existential anguish
return {
	-- lsp-zero: for those who can't be bothered with 20kb lsp config files
	{
		"VonHeikemen/lsp-zero.nvim",
		branch = "v3.x",
		lazy = true,
		config = false,
		init = function()
			-- let's not auto-extend stuff bc we're control freaks
			vim.g.lsp_zero_extend_cmp = 0
			vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},

	-- mason: the package manager that doesn't make u contemplate seppuku
	{
		"williamboman/mason.nvim",
		lazy = false,
		config = true,
	},

	-- mason-lspconfig: linguistic prescriptivism as a service
	{
		"williamboman/mason-lspconfig.nvim",
		lazy = true,
		dependencies = { "williamboman/mason.nvim" },
	},

	-- nvim-lspconfig: the actual brains of the operation
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason.nvim" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
		config = function()
			local lsp_zero = require("lsp-zero")
			local lspconfig = require("lspconfig")
			local mason_lspconfig = require("mason-lspconfig")

			lsp_zero.extend_lspconfig()

			-- global diagnostic config: show errors only, no insert mode updates
			vim.diagnostic.config({
				virtual_text = false, -- disable inline text completely
				signs = true, -- keep the gutter signs
				underline = {
					severity = { min = vim.diagnostic.severity.ERROR },
				},
				update_in_insert = false,
				severity_sort = true,
				float = { -- popup config (re-enabled)
					source = "always",
					border = "rounded",
					header = "",
					prefix = "",
					style = "minimal",
					focusable = false,
					severity_sort = true,
				},
			})

			-- auto-show diagnostics in normal mode for errors only
			vim.api.nvim_create_autocmd("ModeChanged", {
				pattern = "i:n", -- when switching from insert to normal mode
				callback = function()
					vim.diagnostic.open_float({
						scope = "line",
						severity = { min = vim.diagnostic.severity.ERROR },
					})
				end,
			})

			-- standard keybinds setup
			lsp_zero.on_attach(function(client, bufnr)
				-- base keymaps
				lsp_zero.default_keymaps({ buffer = bufnr })

				-- custom keymaps
				local keymap = vim.keymap
				keymap.set(
					"n",
					"gd",
					"<cmd>lua vim.lsp.buf.definition()<cr>",
					{ buffer = bufnr, desc = "Go to definition" }
				)
				keymap.set(
					"n",
					"gr",
					"<cmd>lua vim.lsp.buf.references()<cr>",
					{ buffer = bufnr, desc = "Find references" }
				)
				-- keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", { buffer = bufnr, desc = "Hover docs" })
			end)

			-- manual server setup without mason-lspconfig automatic shit
			local servers = {
				lua_ls = lsp_zero.nvim_lua_ls(),
				clangd = {
					cmd = {
						"clangd",
						"--offset-encoding=utf-16",
						"--header-insertion=never",
						"--clang-tidy=false",
					},
				},
				pyright = {},
				cssls = {},
				html = {},
				svelte = {},
				ts_ls = {},
				glsl_analyzer = {},
				rust_analyzer = {},
			}

			for server, config in pairs(servers) do
				lspconfig[server].setup(config)
			end
		end,
	},

	-- function signature hints that don't make u want to quit programming
	{
		"ray-x/lsp_signature.nvim",
		event = "VeryLazy",
		opts = {
			bind = true,
			doc_lines = 2, -- just gimme the essence
			floating_window = true,
			hint_enable = false, -- no more ghost text
			handler_opts = {
				border = "rounded", -- aesthetic matters
			},
		},
		config = function(_, opts)
			require("lsp_signature").setup(opts)
		end,
	},

	-- conform.nvim: for when u want tab/space wars automated
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					cpp = { "clang-format" },
					c = { "clang-format" },
					hpp = { "clang-format" },
					h = { "clang-format" },
					glsl = { "clang-format" },

					-- rust = { "rustfmt" },

					python = { "autopep8" }, -- black is too opinionated don't @ me
					lua = { "stylua" },
					javascript = { "prettier" },
					js = { "prettier" },
					typescript = { "prettier" },
					svelte = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
				},
				-- format_on_save = { timeout_ms = 500, lsp_fallback = true },
				format_on_save = function(bufnr)
					if vim.bo[bufnr].filetype == "rust" then
						return nil -- skip formatting for rust
					end
					return { timeout_ms = 500, lsp_fallback = true }
				end,
			})

			-- manual format for when autosave isn't ur vibe
			vim.keymap.set({ "n", "v" }, "<leader>mp", function()
				require("conform").format({ async = true, lsp_fallback = true })
			end, { desc = "Format buffer" })
		end,
	},
}
