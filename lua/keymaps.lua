vim.g.user_emmet_expandabbr_key = '`'
vim.g.user_emmet_leader_key = '<C-z>'

vim.g.mapleader = " "


vim.keymap.set('n', '<leader>i', ':w | :!python3 -m manim main.py Main -pql<cr>')

local function run_current_file()
	vim.cmd('write')                              -- Save the current file
	local filetype = vim.bo.filetype
	local filename = vim.fn.expand('%:t')         -- Get the filename with extension
	local filename_no_ext = vim.fn.expand('%:t:r') -- Get the filename without extension
	local filepath = vim.fn.expand('%:p:h')       -- Get the full path without filename

	-- Define common libraries and includes
	local sdl2_includes = '$(sdl2-config --cflags)'
	local sdl2_libs = '$(sdl2-config --libs)'
	local curl_includes = '-I/usr/local/opt/curl/include'
	local curl_libs = '-L/usr/local/opt/curl/lib -lcurl'
	local glfw_includes = '-I/usr/local/include'
	local glfw_libs = '-L/usr/local/lib -lglfw'

	-- Command to run the current file
	if filetype == "python" then
		vim.cmd(string.format('!python3 "%s"', filename))
	elseif filetype == 'javascript' then
		vim.cmd('!node ' .. filename)
	elseif filetype == 'sh' then
		vim.cmd('!sh ' .. filename)
	elseif filetype == 'c' then
		if filename and filename_no_ext then
			local compile_cmd = 'gcc ' ..
					filename ..
					' -o ' ..
					filepath ..
					'/' ..
					filename_no_ext ..
					' ' ..
					sdl2_includes ..
					' ' .. sdl2_libs .. ' ' .. curl_includes .. ' ' .. curl_libs .. ' ' .. glfw_includes .. ' ' .. glfw_libs
			local run_cmd = filepath .. '/' .. filename_no_ext
			vim.cmd('!' .. compile_cmd .. ' && ' .. run_cmd)
		else
			print('Error: Unable to determine filename or filename without extension.')
		end
	elseif filetype == 'cpp' then
		if vim.fn.filereadable("Makefile") == 1 then
			-- use makefile if it exists for any cpp file
			vim.cmd(':w|:vsplit term://make && ./game')
		elseif filename:match("main.cpp") then
			-- raylib-specific compile for main.cpp in raylib dirs
			local raylib_cmd = 'g++ -std=c++17 -o game ' .. filename ..
					' -I$(brew --prefix raylib)/include ' ..
					' -I$(brew --prefix glm)/include ' .. -- add this line for glm
					' -L$(brew --prefix raylib)/lib -lraylib ' ..
					' -framework CoreVideo -framework IOKit -framework Cocoa ' ..
					' -framework GLUT -framework OpenGL'
			vim.cmd(':w|:vsplit term://' .. raylib_cmd .. ' && ./game')
		else
			-- fallback to original g++ command
			vim.cmd(':w|:vsplit term://g++ -o ' ..
				filename_no_ext .. ' ' .. filepath .. '/' .. filename .. ' && ./' .. filename_no_ext)
		end
	else
		print('No run command defined for filetype: ' .. filetype)
	end
end


vim.keymap.set('n', '<leader>r', run_current_file)

vim.keymap.set('n', '<C-Tab>', ':bn<cr>')
vim.keymap.set('n', '<leader><Tab>', ':w | :bn<cr>')
vim.keymap.set('n', '<leader>x', ':bd<cr>')
vim.keymap.set('n', '<C><Tab>', ':bn<cr>')


local function format_code()
	local filetype = vim.bo.filetype
	if filetype == 'python' then
		vim.cmd(':!black %<cr>')
	else
		vim.lsp.buf.format()
	end
end

-- format code using lsp
vim.keymap.set('n', '<leader>=', format_code)

vim.keymap.set({ 'n', 'v' }, 'L', '$')
vim.keymap.set({ 'n', 'v' }, 'H', '_')
vim.keymap.set({ 'n', 'v' }, 'J', 'G')
vim.keymap.set({ 'n', 'v' }, 'K', 'gg')

vim.keymap.set('n', '<Enter>', 'A<Enter><Esc>')

vim.keymap.set('n', '0', '_')
vim.keymap.set('n', '_', '0')
-- USE THE FOLLOWING TO AUTO-CLOSE [ or {
-- vim.api.nvim_set_keymap('i', '[', '[]<left>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('i', '{', '{}<left>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('i', '\'', '\'\'<left>', { noremap = true, silent = true })
-- vim.api.nvim_set_keymap('i', '\"', '\"\"<left>', { noremap = true, silent = true })

-- remap leader e to run python main file
-- vim.keymap.set('n', '<leader>e', ':w|:!python3 main.py<cr>')


vim.keymap.set('n', 'zi', 'zc')
