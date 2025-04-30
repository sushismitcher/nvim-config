-- init.lua
-- bootstrap minimal setup first
require("core.options")
require("core.keymaps")
require("core.autocmds")

-- lazy bootstrap (crucial)
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
	vim.fn.system({
		"git",
		"clone",
		"--filter=blob:none",
		"https://github.com/folke/lazy.nvim.git",
		"--branch=stable",
		lazypath,
	})
end
vim.opt.rtp:prepend(lazypath)

-- now load actual plugins
require("lazy").setup({
	spec = {
		{ import = "plugins" },
	},
	defaults = { lazy = false },
	install = { colorscheme = { "catppuccin" } },
	checker = { enabled = true },
})
