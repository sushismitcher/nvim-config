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
			vim.cmd(":w|:vsplit term://cd build && cmake .. && make && ./game")
		else
			-- build dir exists, just build and run
			vim.cmd(":w|:vsplit term://cd build && make && ./game")
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
		local file_content = vim.fn.system(string.format('cat "%s"', full_path))
		local is_manim_project = string.find(file_content, "from manim") or string.find(file_content, "import manim")
		if is_manim_project then
			vim.cmd(string.format('!manim render "%s" -p', filename))
		else
			vim.cmd(string.format('!python3 "%s"', filename))
		end
	elseif filetype == "rust" then
		vim.cmd(":w|:vsplit term://cargo run")
	elseif filetype == "javascript" then
		vim.cmd("!node " .. filename)
	elseif filetype == "sh" then
		vim.cmd("!sh " .. filename)
	elseif filetype == "html" then
		vim.fn.jobstart({ "open", full_path }, { detach = true })
	elseif filetype == "arduino" or vim.fn.filereadable(".arduino-project") == 1 then
		require("arduino_setup").compile_and_upload()
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
		local project_root = vim.fn.getcwd()

		-- check if cmake project exists
		if vim.fn.filereadable("CMakeLists.txt") == 1 then
			-- cmake build
			vim.cmd(":w|:vsplit term://cmake --build build && ./build/game")
		else
			-- fallback for simple single-file stuff
			vim.cmd(":w|:vsplit term://g++ -std=c++17 -o game " .. filename .. " && ./game")
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

keymap.set("n", "<leader>j", function()
	require("arduino_setup").toggle_compile_output()
end, { desc = "toggle arduino compile output" })
