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

	if vim.fn.filereadable("CMakeLists.txt") == 1 then
		-- assume standard build dir structure
		if vim.fn.isdirectory("build") == 0 then
			-- create build dir if missing
			vim.fn.mkdir("build", "p")
			vim.cmd(":w|:vsplit term://cd build && cmake .. && make && ./app")
		else
			-- build dir exists, just build and run
			vim.cmd(":w|:vsplit term://cd build && make && ./app")
		end
		return
	end

	-- Define common libraries and includes
	local sdl2_includes = "$(sdl2-config --cflags)"
	local sdl2_libs = "$(sdl2-config --libs)"
	local curl_includes = "-I/usr/local/opt/curl/include"
	local curl_libs = "-L/usr/local/opt/curl/lib -lcurl"
	local glfw_includes = "-I/usr/local/opt/glfw/include"
	local glfw_libs =
		"-L/usr/local/opt/glfw/lib -lglfw -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo"

	-- Run commands based on filetype
	if filetype == "python" then
		vim.cmd(string.format('!python3 "%s"', filename))
	elseif filetype == "rust" then
		vim.cmd(":w|:vsplit term://cargo run")
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
			-- check if it's a GLFW project
			local is_glfw = vim.fn.system('grep -l "GLFW" ' .. filename .. " 2>/dev/null") ~= ""
				or vim.fn.system('grep -l "#include <GLFW/glfw3.h>" ' .. filename .. " 2>/dev/null") ~= ""

			if is_glfw then
				-- GLFW C project
				local compile_cmd = "gcc "
					.. filename
					.. " -o "
					.. filepath
					.. "/"
					.. filename_no_ext
					.. " "
					.. glfw_includes
					.. " "
					.. glfw_libs
				local run_cmd = filepath .. "/" .. filename_no_ext
				vim.cmd("!" .. compile_cmd .. " && " .. run_cmd)
			else
				-- regular C project with SDL/curl support
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
				local run_cmd = filepath .. "/" .. filename_no_ext
				vim.cmd("!" .. compile_cmd .. " && " .. run_cmd)
			end
		else
			print("Error: Unable to determine filename or filename without extension.")
		end
	elseif filetype == "cpp" then
		-- detect various cpp project types
		local is_makefile = vim.fn.filereadable("Makefile") == 1
		local is_sfml = vim.fn.system('grep -l "SFML" *.cpp 2>/dev/null') ~= ""
		local is_glfw = vim.fn.system('grep -l "GLFW" *.cpp 2>/dev/null') ~= ""
			or vim.fn.system('grep -l "#include <GLFW/glfw3.h>" *.cpp 2>/dev/null') ~= ""
		local is_raylib = vim.fn.system('grep -l "raylib" *.cpp 2>/dev/null') ~= ""
		local is_main = filename:match("main.cpp")

		-- use dynamic detection based on brew prefix
		local glfw_includes = "-I$(brew --prefix glfw)/include"
		local glm_includes = "-I$(brew --prefix glm)/include"
		local glfw_libs =
			"-L$(brew --prefix glfw)/lib -lglfw -framework OpenGL -framework Cocoa -framework IOKit -framework CoreVideo"

		if is_makefile then
			-- use makefile if it exists for any cpp file
			vim.cmd(":w|:vsplit term://make && ./game")
		elseif is_glfw or (is_main and not is_sfml and not is_raylib) then
			-- prioritize GLFW if detected or if it's main.cpp without other libs
			local glfw_cmd = "g++ -std=c++17 -o game "
				.. filename
				.. " "
				.. glfw_includes
				.. " "
				.. glm_includes
				.. " "
				.. glfw_libs
			vim.cmd(":w|:vsplit term://" .. glfw_cmd .. " && ./game")
			-- notify user that glfw mode was activated
			vim.notify("Compiling with GLFW", vim.log.levels.INFO)
		elseif is_sfml then
			-- SFML-specific compile
			local sfml_includes = "-I$(brew --prefix sfml)/include"
			local sfml_libs = "-L$(brew --prefix sfml)/lib -lsfml-graphics -lsfml-window -lsfml-system -lsfml-audio"
			local sfml_cmd = "g++ -std=c++17 -o game " .. filename .. " " .. sfml_includes .. " " .. sfml_libs
			vim.cmd(":w|:vsplit term://" .. sfml_cmd .. " && ./game")
		elseif is_raylib or is_main then
			-- raylib compile as fallback for main.cpp
			local raylib_cmd = "g++ -std=c++17 -o game "
				.. filename
				.. " -I$(brew --prefix raylib)/include "
				.. " -I$(brew --prefix glm)/include "
				.. " -L$(brew --prefix raylib)/lib -lraylib "
				.. " -framework CoreVideo -framework IOKit -framework Cocoa "
				.. " -framework GLUT -framework OpenGL"
			vim.cmd(":w|:vsplit term://" .. raylib_cmd .. " && ./game")
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

-- hpp/cpp teleporter (zero frills edition)
keymap.set("n", "<leader>w", function()
	vim.cmd("write")
	local current = vim.fn.expand("%:p")
	local ext = vim.fn.expand("%:e")
	local target_file = nil

	-- figure out which dimension we're jumping to
	if ext == "hpp" or ext == "h" then
		target_file = vim.fn.expand("%:p:r") .. ".cpp"
	elseif ext == "cpp" or ext == "cc" then
		target_file = vim.fn.expand("%:p:r") .. ".hpp"
	else
		vim.notify("not a c++ file, abort", vim.log.levels.WARN)
		return
	end

	-- check if target exists, if not, create w/ minimal template
	if vim.fn.filereadable(target_file) == 0 then
		local create = vim.fn.confirm("create " .. target_file .. "?", "&yes\n&no", 1)

		if create == 1 then
			-- ensure dir exists
			local dir = vim.fn.fnamemodify(target_file, ":h")
			if vim.fn.isdirectory(dir) == 0 then
				vim.fn.mkdir(dir, "p")
			end

			-- create file w/ bare minimum content
			local file = io.open(target_file, "w")
			if file then
				local filename = vim.fn.fnamemodify(target_file, ":t:r")

				if ext == "hpp" or ext == "h" then
					-- cpp file gets include, that's it
					file:write('#include "' .. filename .. '.hpp"\n\n')
				else
					-- hpp gets absolutely nothing, as requested
					file:write("")
				end

				file:close()
				vim.notify("created " .. target_file)
			end
		else
			vim.notify("teleport aborted", vim.log.levels.INFO)
			return
		end
	end

	-- yeet into target file
	vim.cmd("edit " .. target_file)
end, { desc = "hpp/cpp switch" })
