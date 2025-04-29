vim.cmd("colorscheme catppuccin-macchiato") -- set color theme

vim.opt.termguicolors = true -- bufferline
require("bufferline").setup{} -- bufferline

vim.api.nvim_set_hl(0, "Comment", { fg = "#eef200" })
vim.api.nvim_set_hl(0, "@comment", { link = "Comment" })
