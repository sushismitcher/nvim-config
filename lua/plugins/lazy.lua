local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable", -- latest stable release
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
	-- {
	-- 	"ThePrimeagen/harpoon",
	-- 	branch = "harpoon2",
	-- 	dependencies = { "nvim-lua/plenary.nvim" },
	-- 	config = function()
	-- 		local harpoon = require("harpoon")
	-- 		harpoon:setup()
	-- 	
	-- 		-- keymaps that actually slap
	-- 		vim.keymap.set("n", "<leader>a", function() harpoon:list():add() end)
	-- 		vim.keymap.set("n", "<C-e>", function() harpoon.ui:toggle_quick_menu(harpoon:list()) end)
	-- 	
	-- 		-- nav between marked files like a chad
	-- 		vim.keymap.set("n", "<C-h>", function() harpoon:list():select(1) end)
	-- 		vim.keymap.set("n", "<C-j>", function() harpoon:list():select(2) end)
	-- 		vim.keymap.set("n", "<C-k>", function() harpoon:list():select(3) end)
	-- 		vim.keymap.set("n", "<C-l>", function() harpoon:list():select(4) end)
	-- 	end,
	-- },
	{
		'stevearc/oil.nvim',
		dependencies = { "nvim-tree/nvim-web-devicons" },
		config = function()
			require("oil").setup({
				default_file_explorer = true,
				keymaps = {
					["g?"] = "actions.show_help",
					["<CR>"] = "actions.select",
					["<C-v>"] = "actions.select_vsplit",
					["<C-s>"] = "actions.select_split",
					["<C-t>"] = "actions.select_tab",
					["-"] = "actions.parent",
					["_"] = "actions.open_cwd",
					["`"] = "actions.cd",
					["~"] = "actions.tcd",
					["g."] = "actions.toggle_hidden",
				},
				use_default_keymaps = false,
			})
			vim.keymap.set("n", "-", require("oil").open, { desc = "Open file explorer" })
		end
	},
	-- {
	-- 	'Exafunction/codeium.nvim',
	-- 	dependencies = {
	-- 		'nvim-lua/plenary.nvim',
	-- 		'hrsh7th/nvim-cmp',
	-- 	},
	-- 	config = function()
	-- 		require('codeium').setup({})
	-- 	end
	-- },
	{
		"neovim/nvim-lspconfig",
		dependencies = {
			"williamboman/mason.nvim",
			"williamboman/mason-lspconfig.nvim",
		},
	},
	{ "hrsh7th/nvim-cmp" },
	{ "hrsh7th/cmp-nvim-lsp" },

	-- optional but god-tier
	{ "p00f/clangd_extensions.nvim" }, -- clangd flex
	{ "mfussenegger/nvim-dap" },      -- debugging bc printf is for peasants
	{ "rcarriga/nvim-dap-ui" },       -- pretty debuggy bois
	{
		"nvim-treesitter/nvim-treesitter",
		build = ":TSUpdate",
		config = function()
			require("nvim-treesitter.configs").setup({
				ensure_installed = { "svelte", "typescript", "javascript", "css", "html", "cpp", "c" },
				highlight = { enable = true },
			})
			-- require("nvim-treesitter.configs").setup({
			-- 	ensure_installed = { "svelte", "typescript", "javascript", "css", "html", "cpp", "c" },
			-- 	highlight = { enable = true },
			-- 	-- Add this section:
			-- 	indent = { enable = true },
			-- 	incremental_selection = {
			-- 		enable = true,
			-- 		keymaps = {
			-- 			init_selection = "<CR>",
			-- 			node_incremental = "<CR>",
			-- 			scope_incremental = "<S-CR>",
			-- 			node_decremental = "<BS>",
			-- 		},
			-- 	},
			-- })
		end
	},
	-- 	{
	--     "nvim-treesitter/nvim-treesitter-context",
	--     dependencies = { "nvim-treesitter/nvim-treesitter" },
	--     config = function()
	--         require("treesitter-context").setup({
	--             enable = true,
	--             max_lines = 3,
	--             trim_scope = "outer",
	--             mode = 'cursor',  -- 'cursor' or 'topline'
	--             zindex = 20,
	--             patterns = {
	--                 default = {
	--                     'class',
	--                     'function',
	--                     'method',
	--                     'for',
	--                     'while',
	--                     'if',
	--                     'switch',
	--                     'case',
	--                 },
	--                 cpp = {
	--                     'class_definition',
	--                     'function_definition',
	--                     'method_definition',
	--                     'for_statement',
	--                     'while_statement',
	--                     'if_statement',
	--                     'switch_statement',
	--                     'case_statement',
	--                     'struct_declaration',
	--                     'namespace_definition',
	--                 },
	--             },
	--         })
	--     end,
	-- },
	{
		"stevearc/conform.nvim",
		event = { "BufWritePre" },
		cmd = { "ConformInfo" },
		config = function()
			require("conform").setup({
				formatters_by_ft = {
					cpp = { "clang-format" },
					c = { "clang-format" },
					-- python = {
					-- 	-- "yapf"
					-- 	"autopep8",
					-- 	prepend_args = { "--indent-size=2", "--aggressive", "--aggressive" },
					-- },
					-- python = { "black" }, -- might as well add this for ur python stuff
				},
				format_on_save = { timeout_ms = 500, lsp_fallback = true },
				-- keymaps so u can manually format when needed
				vim.keymap.set({ "n", "v" }, "<leader>mp", function()
					require("conform").format({ async = true, lsp_fallback = true })
				end, { desc = "Format buffer" }),
			})
		end,
	},
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			-- marks = special snowflakes rn
			marks = true,
			-- shows registers when u hit "
			registers = true,
			-- spelling suggestions on z=
			spelling = {
				enabled = true,
				suggestions = 20,
			}
		}
	},
	{
		"mattn/emmet-vim",
		event = "VeryLazy" -- bc we're civilized here
	},
	-- {
	-- 	"kevinhwang91/nvim-ufo",
	-- 	dependencies = {
	-- 		"kevinhwang91/promise-async" -- Required dependency
	-- 	},
	-- 	config = function()
	-- 		require("ufo").setup({
	-- 			provider_selector = function(bufnr, filetype, buftype)
	-- 				return { "lsp", "indent" } -- Use LSP for folding, fallback to indent
	-- 			end
	-- 		})
	-- 		-- vim.o.foldcolumn = '1'
	-- 		vim.o.foldlevel = 2 -- Using ufo provider need a large value, feel free to decrease the value
	-- 		vim.o.foldlevelstart = 99
	-- 		-- vim.o.foldenable = true
	-- 	end,
	-- },
	{
		"ThePrimeagen/vim-be-good",
		cmd = "VimBeGood",
	},
	{ "catppuccin/nvim",          name = "catppuccin",                       priority = 1000 },
	{
		'nvim-telescope/telescope.nvim',
		tag = '0.1.6',
		dependencies = { 'nvim-lua/plenary.nvim' }
	},
	-- EASY MOTIONS
	{
		"easymotion/vim-easymotion",
		lazy = false,
		opts = {
			-- Add any plugin-specific options here
		},
		config = function(_, opts)
			-- Configure the plugin
			vim.g.EasyMotion_do_mapping = 0 -- Disable default mappings
			vim.g.EasyMotion_smartcase = 1 -- Enable smart-case match

			-- Set up custom keymappings
			-- vim.keymap.set("n", "<Leader>s", "<Plug>(easymotion-s2)")
			vim.keymap.set("n", ".", "<Plug>(easymotion-s2)")
			vim.keymap.set("n", "<Leader>t", "<Plug>(easymotion-t2)")
		end,
	},

	-- file tree:
	-- {
	-- 	"nvim-tree/nvim-tree.lua",
	-- 	version = "*",
	-- 	lazy = false,
	-- 	dependencies = {
	-- 		"nvim-tree/nvim-web-devicons",
	-- 	},
	-- 	config = function()
	-- 		require("nvim-tree").setup {}
	-- 	end,
	-- },

	--visualize buffers as tabs
	-- { 'akinsho/bufferline.nvim', version = "*",       dependencies = 'nvim-tree/nvim-web-devicons' },
	{
		'akinsho/bufferline.nvim',
		version = "*",
		dependencies = 'nvim-tree/nvim-web-devicons',
		config = function()
			require("bufferline").setup {}
			-- leader+a/s/d to switch tabs
			vim.keymap.set("n", "<leader>a", ":BufferLineGoToBuffer 1<CR>", { silent = true })
			vim.keymap.set("n", "<leader>s", ":BufferLineGoToBuffer 2<CR>", { silent = true })
			vim.keymap.set("n", "<leader>d", ":BufferLineGoToBuffer 3<CR>", { silent = true })
		end
	},
	{
		"iamcco/markdown-preview.nvim",
		cmd = { "MarkdownPreviewToggle" },
		ft = { "markdown" },
		build = function() vim.fn["mkdp#util#install"]() end,
	},
	{
		'terrortylor/nvim-comment',
		config = function()
			require("nvim_comment").setup({ create_mappings = false })
		end
	},
	-- save and load sessions
	-- {
	-- 	'rmagatti/auto-session',
	-- 	config = function()
	-- 		require("auto-session").setup {
	-- 			log_level = "error",
	-- 			auto_session_suppress_dirs = { "~/" },
	-- 		}
	-- 	end
	-- },
	{
		'VonHeikemen/lsp-zero.nvim',
		branch = 'v3.x',
		lazy = true,
		config = false,
		init = function()
			-- Disable automatic setup, we are doing it manually
			vim.g.lsp_zero_extend_cmp = 0
			vim.g.lsp_zero_extend_lspconfig = 0
		end,
	},
	{
		'williamboman/mason.nvim',
		lazy = false,
		config = true,
	},
	{ "ray-x/lsp_signature.nvim", dependencies = { "neovim/nvim-lspconfig" } },
	{
		'hrsh7th/nvim-cmp',
		event = 'InsertEnter',
		dependencies = {
			{ 'L3MON4D3/LuaSnip' },
			{ 'hrsh7th/cmp-nvim-lsp' },
		},
		config = function()
			local lsp_zero = require('lsp-zero')
			lsp_zero.extend_cmp()

			local cmp = require('cmp')
			require('lsp_signature').setup({
				bind = true,
				doc_lines = 2,
				floating_window = true,
				hint_enable = false,
				handler_opts = {
					border = "rounded"
				}
			})
			local cmp_action = lsp_zero.cmp_action()

			cmp.setup({
				formatting = lsp_zero.cmp_format({ details = true }),
				-- mapping = cmp.mapping.preset.insert({
				-- 	['<Tab>'] = cmp.mapping.confirm({ select = true }),
				-- 	['<C-u>'] = cmp.mapping.scroll_docs(-4),
				-- 	['<C-d>'] = cmp.mapping.scroll_docs(4),
				-- 	['<C-f>'] = cmp_action.luasnip_jump_forward(),
				-- 	['<C-b>'] = cmp_action.luasnip_jump_backward(),
				-- }),
				snippet = {
					expand = function(args)
						require('luasnip').lsp_expand(args.body)
					end,
				},
				sources = {
					-- { name = 'codeium',  priority = 500 },
					-- { name = 'nvim_lsp', priority = 1000 },
					-- { name = 'luasnip',  priority = 750 },
					{ name = 'codeium' },
					{ name = 'nvim_lsp' },
					{ name = 'luasnip' },
					-- Add other sources here if needed
				},
				window = {
					documentation = {
						border = { "╭", "─", "╮", "│", "╯", "─", "╰", "│" },
						winhighlight = "Normal:CmpDocumentation,FloatBorder:CmpDocumentationBorder",
						max_width = 80,
						max_height = 12,
					},
				},

				-- modify your mapping section:
				mapping = cmp.mapping.preset.insert({
					['<Tab>'] = cmp.mapping.confirm({ select = true }),
					['<C-u>'] = cmp.mapping.scroll_docs(-4),
					['<C-d>'] = cmp.mapping.scroll_docs(4),
					['<C-f>'] = cmp_action.luasnip_jump_forward(),
					['<C-b>'] = cmp_action.luasnip_jump_backward(),

					-- add these lines for cycling with documentation:
					['<Down>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_next_item()
							-- show docs for selected item
							cmp.event:emit('complete_done', cmp.get_selected_entry())
						else
							fallback()
						end
					end, { 'i', 's' }),

					['<Up>'] = cmp.mapping(function(fallback)
						if cmp.visible() then
							cmp.select_prev_item()
							-- show docs for selected item
							cmp.event:emit('complete_done', cmp.get_selected_entry())
						else
							fallback()
						end
					end, { 'i', 's' }),
				}),

				-- set this to show docs only when cycling/selecting:
				experimental = {
					ghost_text = true,
				},
			})
			vim.cmd([[
				" Only show documentation when an item is selected
				augroup CmpDocumentation
					autocmd!
					autocmd User CmpCompleteDone lua require('cmp').close({ reason = require('cmp').ContextReason.TriggerOnly })
				augroup END
			]])
		end
	},
	-- {
	-- 	'neovim/nvim-lspconfig',
	-- 	cmd = { 'LspInfo', 'LspInstall', 'LspStart' },
	-- 	event = { 'BufReadPre', 'BufNewFile' },
	-- 	dependencies = {
	-- 		{ 'hrsh7th/cmp-nvim-lsp' },
	-- 		{ 'williamboman/mason-lspconfig.nvim' },
	-- 	},
	-- 	config = function()
	-- 		local lspconfig = require('lspconfig')
	-- 		local lsp_zero = require('lsp-zero')
	-- 		local cmp_nvim_lsp = require('cmp_nvim_lsp')
	--
	-- 		lsp_zero.extend_lspconfig()
	--
	-- 		local capabilities = vim.lsp.protocol.make_client_capabilities()
	-- 		capabilities = cmp_nvim_lsp.default_capabilities(capabilities)
	--
	-- 		lsp_zero.on_attach(function(client, bufnr)
	-- 			lsp_zero.default_keymaps({ buffer = bufnr })
	-- 		end)
	--
	--
	-- 		require('mason-lspconfig').setup({
	-- 			ensure_installed = { "pyright", "svelte", "cssls", "clangd" },
	-- 			handlers = {
	-- 				clangd = function()
	-- 					lspconfig.clangd.setup({
	-- 						capabilities = capabilities,
	-- 						cmd = {
	-- 							"clangd",
	-- 							"--offset-encoding=utf-16",
	-- 							"--header-insertion=never",
	-- 							"--clang-tidy=false"
	-- 						},
	-- 						on_attach = function(client, bufnr)
	-- 							-- we keep ur existing error display setup
	-- 							client.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	-- 								vim.lsp.diagnostic.on_publish_diagnostics, {
	-- 									update_in_insert = false,
	-- 									severity_sort = true,
	-- 									virtual_text = false,
	-- 									signs = { severity = { min = vim.diagnostic.severity.ERROR } },
	-- 									underline = false,
	-- 									virtual_lines = false,
	-- 								}
	-- 							)
	-- 						end
	-- 					})
	-- 				end,
	--
	--
	-- 				function(server_name)
	-- 					lspconfig[server_name].setup({
	-- 						capabilities = capabilities,
	-- 						on_attach = function(client, bufnr)
	-- 							client.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	-- 								vim.lsp.diagnostic.on_publish_diagnostics, {
	-- 									-- virtual_text = {
	-- 									-- 	severity = { min = vim.diagnostic.severity.ERROR },
	-- 									-- },
	-- 									-- signs = {
	-- 									-- 	severity = { min = vim.diagnostic.severity.ERROR },
	-- 									-- },
	-- 									-- underline = {
	-- 									-- 	severity = { min = vim.diagnostic.severity.ERROR },
	-- 									-- },
	-- 									update_in_insert = false,
	-- 									severity_sort = true,
	-- 									virtual_text = false, -- Disable virtual text
	-- 									signs = {
	-- 										severity = { min = vim.diagnostic.severity.ERROR },
	-- 									},       -- Show only errors in signs
	-- 									update_in_insert = false,
	-- 									underline = false, -- Disable underline
	-- 									severity_sort = false,
	-- 									virtual_lines = false,
	-- 								}
	-- 							)
	-- 							-- client.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
	-- 							-- 	vim.lsp.diagnostic.on_publish_diagnostics, {
	-- 							-- 		virtual_text = false,
	-- 							-- 		signs = true,
	-- 							-- 		update_in_insert = false,
	-- 							-- 		underline = false,
	-- 							-- 		severity_sort = false,
	-- 							-- 		virtual_lines = false,
	-- 							-- 		handlers = {
	-- 							-- 			["textDocument/publishDiagnostics"] = custom_diagnostics_handler
	-- 							-- 		},
	-- 							-- 	}
	-- 							-- )
	-- 						end
	-- 					})
	-- 				end,
	-- 			
	-- 				lua_ls = function()
	-- 					local lua_opts = lsp_zero.nvim_lua_ls()
	-- 					lspconfig.lua_ls.setup(lua_opts)
	-- 				end,
	-- 			}
	-- 		})
	-- 	end
	-- },
})
