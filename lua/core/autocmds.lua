-- auto commands

local augroup = vim.api.nvim_create_augroup -- create/get autocommand group
local autocmd = vim.api.nvim_create_autocmd -- create autocommand

-- remove whitespace on save
autocmd("BufWritePre", {
  pattern = "*",
  command = ":%s/\\s\\+$//e",
})

-- don't auto comment new lines
 autocmd("BufEnter", {
  pattern = "*",
  command = "set fo-=c fo-=r fo-=o",
})

