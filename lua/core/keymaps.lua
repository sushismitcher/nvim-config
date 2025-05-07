-- key mappings module

local keymap = vim.keymap -- for conciseness

---------------------
-- General Keymaps --
---------------------

-- move selected lines
keymap.set("v", "<M-j>", ":m '>+1<CR>gv=gv")
keymap.set("v", "<M-k>", ":m '<-2<CR>gv=gv")

keymap.set("n", "<leader><tab>", ":bnext<CR>", { noremap = true, silent = true, desc = "Next buffer" })

-- paste w/o replacing the contents of the clipboard
keymap.set("x", "<leader>p", '"_DP')

-- superior line navigation (ur custom movements)
keymap.set({ "n", "v" }, "L", "$", { desc = "Go to end of line" })
keymap.set({ "n", "v" }, "H", "_", { desc = "Go to start of line" })
keymap.set({ "n", "v" }, "J", "G", { desc = "Go to end of file" })
keymap.set({ "n", "v" }, "K", "gg", { desc = "Go to start of file" })

-- swap 0 and _ (start of line vs first non-blank char)
keymap.set("n", "0", "_", { desc = "Go to first non-blank character" })
keymap.set("n", "_", "0", { desc = "Go to start of line" })

-- add new line without entering insert mode
keymap.set("n", "<Enter>", "A<Enter><Esc>", { desc = "Add line below" })

-- run current file (preserving ur setup)
keymap.set("n", "<leader>r", function()
	vim.cmd("write") -- Save the current file
	local filetype = vim.bo.filetype
	local filename = vim.fn.expand("%:t") -- Get filename with extension
	local filename_no_ext = vim.fn.expand("%:t:r") -- Filename without extension
	local filepath = vim.fn.expand("%:p:h") -- Full path without filename
	local full_path = vim.fn.expand("%:p") -- Full path with filename

	-- Define common libraries and includes
	local sdl2_includes = "$(sdl2-config --cflags)"
	local sdl2_libs = "$(sdl2-config --libs)"
	local curl_includes = "-I/usr/local/opt/curl/include"
	local curl_libs = "-L/usr/local/opt/curl/lib -lcurl"
	local glfw_includes = "-I/usr/local/include"
	local glfw_libs = "-L/usr/local/lib -lglfw"

	-- Run commands based on filetype
	if filetype == "python" then
		vim.cmd(string.format('!python3 "%s"', filename))
	elseif filetype == "javascript" then
		vim.cmd("!node " .. filename)
	elseif filetype == "sh" then
		vim.cmd("!sh " .. filename)
	elseif filetype == "html" then
		-- ultra-minimal live-server implementation - zero buffer trash
		local relative_path = vim.fn.expand("%")
		local cwd = vim.fn.getcwd()

		-- Check if server already running via background job
		local server_pid = vim.g.live_server_pid
		local server_running = server_pid and vim.fn.jobwait({ server_pid }, 0)[1] == -1

		if not server_running then
			-- silently start server in background, no buffer spawned
			local cmd = string.format(
				"live-server --browser=chrome --port=8080 --no-css-inject --open=%s --quiet %s",
				relative_path,
				cwd
			)

			-- launch in background via jobstart, store pid for later
			vim.g.live_server_pid = vim.fn.jobstart(cmd, {
				detach = true,
				on_exit = function(_, code)
					if code ~= 0 then
						print("live-server crashed or closed. code: " .. code)
					end
				end,
			})

			print("live-server running → http://localhost:8080/" .. relative_path)
		else
			print("live-server already running - save to refresh")
			-- force open browser if it's not already open
			vim.fn.jobstart("open http://localhost:8080/" .. relative_path, { detach = true })
		end
	elseif filetype == "c" then
		if filename and filename_no_ext then
			local compile_cmd = "gcc "
				.. filename
				.. " -o "
				.. filepath
				.. "/"
				.. filename_no_ext
				.. " "
				.. sdl2_includes
				.. " "
				.. sdl2_libs
				.. " "
				.. curl_includes
				.. " "
				.. curl_libs
				.. " "
				.. glfw_includes
				.. " "
				.. glfw_libs
			local run_cmd = filepath .. "/" .. filename_no_ext
			vim.cmd("!" .. compile_cmd .. " && " .. run_cmd)
		else
			print("Error: Unable to determine filename or filename without extension.")
		end
	-- in keymaps.lua, inside the <leader>r function
	elseif filetype == "cpp" then
		-- detect if it's an SFML project (look for SFML headers or main file pattern)
		local is_sfml = vim.fn.system('grep -l "SFML" *.cpp 2>/dev/null') ~= ""
		local is_glfw = vim.fn.system('grep -l "GLFW" *.cpp 2>/dev/null') ~= ""
			or vim.fn.system('grep -l "#include <GLFW/glfw3.h>" *.cpp 2>/dev/null') ~= ""

		if vim.fn.filereadable("Makefile") == 1 then
			-- use makefile if it exists for any cpp file
			vim.cmd(":w|:vsplit term://make && ./game")
		elseif is_glfw or filename:match("main.cpp") then
			-- GLFW-specific compile with explicit glm include
			local glfw_includes = "-I$(brew --prefix glfw)/include"
			local glm_includes = "-I$(brew --prefix glm)/include"
			local glfw_libs =
				"-L$(brew --prefix glfw)/lib -lglfw -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo"

			-- GLFW compile command with glm
			local glfw_cmd = "g++ -std=c++17 -o game "
				.. filename
				.. " "
				.. glfw_includes
				.. " "
				.. glm_includes
				.. " "
				.. glfw_libs
			vim.cmd(":w|:vsplit term://" .. glfw_cmd .. " && ./game")
		elseif is_sfml or filename:match("main.cpp") then
			-- SFML-specific compile (added alongside raylib)
			local sfml_includes = "-I$(brew --prefix sfml)/include"
			local sfml_libs = "-L$(brew --prefix sfml)/lib -lsfml-graphics -lsfml-window -lsfml-system -lsfml-audio"

			-- decide which lib to use based on imports or ask user
			if is_sfml then
				-- SFML compile command
				local sfml_cmd = "g++ -std=c++17 -o game " .. filename .. " " .. sfml_includes .. " " .. sfml_libs
				vim.cmd(":w|:vsplit term://" .. sfml_cmd .. " && ./game")
			else
				-- raylib compile (existing code)
				local raylib_cmd = "g++ -std=c++17 -o game "
					.. filename
					.. " -I$(brew --prefix raylib)/include "
					.. " -I$(brew --prefix glm)/include "
					.. " -L$(brew --prefix raylib)/lib -lraylib "
					.. " -framework CoreVideo -framework IOKit -framework Cocoa "
					.. " -framework GLUT -framework OpenGL"
				vim.cmd(":w|:vsplit term://" .. raylib_cmd .. " && ./game")
			end
		else
			-- fallback to original g++ command
			vim.cmd(
				":w|:vsplit term://g++ -o "
					.. filename_no_ext
					.. " "
					.. filepath
					.. "/"
					.. filename
					.. " && ./"
					.. filename_no_ext
			)
		end
	else
		print("No run command defined for filetype: " .. filetype)
	end
end, { desc = "Run current file" })
