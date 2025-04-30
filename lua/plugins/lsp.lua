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
		lazy = false,
		opts = {
			ensure_installed = {
				"clangd", -- c/c++ but with unnecessary complexity
				"pyright", -- python's typechecker that's somehow both strict and permissive
				"lua_ls", -- for when u wanna be told ur nvim config is trash
				"cssls", -- tells u ur css is bad even tho it works
				"html", -- bc apparently html needs a server now
				"svelte", -- for that project u'll abandon in 2 weeks
			},
			automatic_installation = true, -- for the chronically impatient
		},
	},

	-- nvim-lspconfig: the actual brains of the operation
	{
		"neovim/nvim-lspconfig",
		cmd = { "LspInfo", "LspInstall", "LspStart" },
		event = { "BufReadPre", "BufNewFile" },
		dependencies = {
			{ "hrsh7th/cmp-nvim-lsp" },
			{ "williamboman/mason-lspconfig.nvim" },
		},
		config = function()
			local lsp_zero = require("lsp-zero")
			lsp_zero.extend_lspconfig()

			-- make lsp less passive-aggressive
			vim.diagnostic.config({
				virtual_text = false, -- still no inline spam
				signs = true, -- keep the signs
				underline = true, -- underline where issues exist
				update_in_insert = false, -- peace while typing
				severity_sort = true,
				-- float = { -- the floating window that appears on hover
				-- 	focusable = false,
				-- 	source = "always",
				-- 	header = "",
				-- 	prefix = "",
				-- 	style = "minimal", -- clean aesthetic
				-- },
			})

			-- make diagnostic signs subtle af
			local signs = { Error = "•", Warn = "•", Hint = "•", Info = "•" }
			for type, icon in pairs(signs) do
				local hl = "DiagnosticSign" .. type
				vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = "" })
			end

			-- keybinds that don't require memorizing the necronomicon
			lsp_zero.on_attach(function(client, bufnr)
				-- base keymaps
				lsp_zero.default_keymaps({ buffer = bufnr })

				-- extra keymaps for the enlightened
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
				keymap.set("n", "K", "<cmd>lua vim.lsp.buf.hover()<cr>", { buffer = bufnr, desc = "Hover docs" })
			end)

			-- lua_ls but for nvim specifically
			require("lspconfig").lua_ls.setup(lsp_zero.nvim_lua_ls())

			-- clangd: for when cpp isn't complex enough already
			require("lspconfig").clangd.setup({
				cmd = {
					"clangd",
					"--offset-encoding=utf-16", -- bc standards are too mainstream
					"--header-insertion=never", -- don't bloat my files pls
					"--clang-tidy=false", -- let me write bad code in peace
				},
				on_attach = function(client, bufnr)
					-- custom error display or lack thereof
					client.handlers["textDocument/publishDiagnostics"] =
						vim.lsp.with(vim.lsp.diagnostic.on_publish_diagnostics, {
							update_in_insert = false,
							severity_sort = true,
							virtual_text = false,
							signs = { severity = { min = vim.diagnostic.severity.ERROR } },
							underline = false,
							virtual_lines = false,
						})
				end,
			})

			-- setup other servers without all the drama
			require("mason-lspconfig").setup_handlers({
				function(server_name)
					-- skip the manually config'd ones
					if server_name ~= "clangd" and server_name ~= "lua_ls" then
						require("lspconfig")[server_name].setup({})
					end
				end,
			})
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
					python = { "autopep8" }, -- black is too opinionated don't @ me
					lua = { "stylua" },
					javascript = { "prettier" },
					typescript = { "prettier" },
					svelte = { "prettier" },
					css = { "prettier" },
					html = { "prettier" },
				},
				format_on_save = { timeout_ms = 500, lsp_fallback = true },
			})

			-- manual format for when autosave isn't ur vibe
			vim.keymap.set({ "n", "v" }, "<leader>mp", function()
				require("conform").format({ async = true, lsp_fallback = true })
			end, { desc = "Format buffer" })
		end,
	},
}
