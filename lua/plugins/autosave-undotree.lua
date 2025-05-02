-- autosave + persistent undo setup
-- bc ctrl+z/ctrl+y was never enough & saving is 4 boomers

return {
	-- part 1: autosave functionality (stealth mode)
	-- {
	-- 	"pocco81/auto-save.nvim",
	-- 	event = { "InsertLeave", "TextChanged" },
	-- 	config = function()
	-- 		require("auto-save").setup({
	-- 			enabled = true,
	-- 			-- ghost mode - no msgs
	-- 			execution_message = {
	-- 				message = function()
	-- 					return ""
	-- 				end,
	-- 			},
	-- 			-- only triggers when leaving insert mode or after text changes
	-- 			trigger_events = { "InsertLeave", "TextChanged" },
	-- 			-- wait 500ms after typing stops
	-- 			debounce_delay = 500,
	-- 			-- ignore certain filetypes
	-- 			condition = function(buf)
	-- 				local ignored = { "TelescopePrompt", "fugitive", "oil", "neo-tree" }
	-- 				local ft = vim.bo[buf].filetype
	-- 				return vim.bo[buf].modifiable and not vim.tbl_contains(ignored, ft)
	-- 			end,
	-- 			write_all_buffers = false, -- only save current buffer
	-- 		})
	--
	-- 		-- toggle autosave with <leader>as
	-- 		vim.keymap.set("n", "<leader>as", require("auto-save").toggle, { desc = "Toggle autosave" })
	-- 	end,
	-- },

	-- part 2: god-tier undo history visualization
	{
		"mbbill/undotree",
		event = "VeryLazy",
		config = function()
			-- set up persistent undo history
			local undodir = vim.fn.stdpath("data") .. "/undodir"

			-- create undodir if it doesn't exist
			if vim.fn.isdirectory(undodir) == 0 then
				vim.fn.mkdir(undodir, "p")
			end

			-- enable persistent undo + set location
			vim.opt.undofile = true
			vim.opt.undodir = undodir

			-- set ridiculously high undo levels, but not TOO high
			vim.opt.undolevels = 5000

			-- how many lines to save for offline undo
			vim.opt.undoreload = 5000

			-- only track meaningful changes to prevent undotree overload
			-- WAY fewer undo states = cleaner undotree
			vim.opt.updatetime = 3000 -- 3s between automatic state saves

			-- use default undotree settings - the custom params broke it
			vim.g.undotree_SetFocusWhenToggle = 1
			vim.g.undotree_WindowLayout = 2 -- slightly better layout

			-- toggle undotree panel with actual fn not cmd
			vim.keymap.set("n", "<leader>u", function()
				vim.cmd("UndotreeToggle")
			end, { desc = "Toggle Undotree" })

			-- toggle undotree panel
			vim.keymap.set("n", "<leader>u", vim.cmd.UndotreeToggle, { desc = "Toggle Undotree" })
		end,
	},
}
