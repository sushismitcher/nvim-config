-- key mappings module

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps --
---------------------

-- superior line navigation (ur custom movements)
keymap.set({ "n", "v" }, "L", "$", { desc = "Go to end of line" })
keymap.set({ "n", "v" }, "H", "_", { desc = "Go to start of text" })
keymap.set({ "n", "v" }, "J", "G", { desc = "Go to end of file" })
keymap.set({ "n", "v" }, "K", "gg", { desc = "Go to start of file" })

-- swap 0 and _ (start of line vs first non-blank char)
keymap.set("n", "0", "_", { desc = "Go to first non-blank character" })
keymap.set("n", "_", "0", { desc = "Go to start of line" })

-- add new line without entering insert mode
keymap.set("n", "<Enter>", "A<Enter><Esc>", { desc = "Add line below" })

-- run current file (preserving ur setup)
keymap.set('n', '<leader>r', function()
  vim.cmd('write')                              -- Save the current file
  local filetype = vim.bo.filetype
  local filename = vim.fn.expand('%:t')         -- Get filename with extension
  local filename_no_ext = vim.fn.expand('%:t:r') -- Filename without extension
  local filepath = vim.fn.expand('%:p:h')       -- Full path without filename

  -- Define common libraries and includes
  local sdl2_includes = '$(sdl2-config --cflags)'
  local sdl2_libs = '$(sdl2-config --libs)'
  local curl_includes = '-I/usr/local/opt/curl/include'
  local curl_libs = '-L/usr/local/opt/curl/lib -lcurl'
  local glfw_includes = '-I/usr/local/include'
  local glfw_libs = '-L/usr/local/lib -lglfw'

  -- Run commands based on filetype
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
end, { desc = "Run current file" })

