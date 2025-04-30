-- general settings
vim.g.mapleader = " "                   -- space as leader key
vim.g.maplocalleader = " "              -- space as localleader

local opt = vim.opt                     -- for conciseness

-- line numbers
opt.number = true                       -- show line numbers
opt.relativenumber = true               -- show relative line numbers

-- tabs & indentation
opt.tabstop = 2                         -- 2 spaces for tabs
opt.shiftwidth = 2                      -- 2 spaces for indent width
opt.expandtab = false                   -- don't expand tab to spaces
opt.autoindent = true                   -- copy indent from current line when starting new one

-- line wrapping
opt.wrap = false                        -- disable line wrapping

-- search settings
opt.ignorecase = true                   -- ignore case when searching
opt.smartcase = true                    -- if you include mixed case in search, assumes case-sensitive

-- cursor line
opt.cursorline = true                   -- highlight the current cursor line

-- appearance
opt.termguicolors = true                -- true color support
opt.signcolumn = "yes"                  -- show sign column so text doesn't shift

-- backspace
opt.backspace = "indent,eol,start"      -- allow backspace on indent, end of line, or insert mode start

-- clipboard
opt.clipboard:append("unnamedplus")     -- use system clipboard

-- split windows
opt.splitright = true                   -- split vertical window to the right
opt.splitbelow = true                   -- split horizontal window to the bottom

-- considered as part of word
opt.iskeyword:append("-")               -- consider string-string as whole word

-- scrolling
opt.scrolloff = 8                       -- min num of screen lines to keep above/below cursor
