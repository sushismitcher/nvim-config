vim.keymap.set('n', '<leader>p', ':Telescope find_files<cr>')
vim.keymap.set('n', '<leader>f', ':Telescope live_grep<cr>')

--tree
-- vim.keymap.set('n', '<leader>k', ':NvimTreeFindFileToggle<CR>')
vim.keymap.set('n', '<leader>k', ':e .<CR>')

-- vim.keymap.set('n', '<leader>r', ':w <CR>| :!python3 main.py<CR>')

vim.keymap.set({ 'n', 'v' }, '<leader>/', ':CommentToggle<cr>')
