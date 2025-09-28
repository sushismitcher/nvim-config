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

-- cmake auto-generation system (bulletproof edition)
local function detect_includes(filepath)
	if not filepath or filepath == "" then
		return {}
	end

	local file = io.open(filepath, "r")
	if not file then
		return {}
	end

	local includes = {}
	for line in file:lines() do
		if line and line:match("^%s*#include") then
			if line:match('[<"]raylib%.h[>"]') then
				includes.raylib = true
			elseif line:match('[<"]GLFW/') then
				includes.glfw = true
			elseif line:match('[<"]glm/') then
				includes.glm = true
			elseif line:match('[<"]SFML/') then
				includes.sfml = true
			end
		end
	end
	file:close()
	return includes
end

local function generate_cmake(project_root, filename, includes)
	if not project_root or not filename or not includes then
		vim.notify("generate_cmake: missing required params", vim.log.levels.ERROR)
		return false
	end

	local cmake_content = string.format(
		[[cmake_minimum_required(VERSION 3.20)
project(%s)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)

]],
		filename:match("(.+)%.cpp$") or "game"
	)

	-- get homebrew prefix paths (fixed duplicate raylib block)
	if includes.raylib then
		cmake_content = cmake_content
			.. [[
# raylib via homebrew (manual paths bc no cmake config)
execute_process(COMMAND brew --prefix raylib OUTPUT_VARIABLE RAYLIB_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
set(RAYLIB_INCLUDE_DIR "${RAYLIB_PREFIX}/include")
set(RAYLIB_LIBRARY_DIR "${RAYLIB_PREFIX}/lib")
]]
	end

	if includes.glfw then
		cmake_content = cmake_content
			.. [[
# glfw via homebrew
execute_process(COMMAND brew --prefix glfw OUTPUT_VARIABLE GLFW_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
set(GLFW_INCLUDE_DIR "${GLFW_PREFIX}/include")
set(GLFW_LIBRARY_DIR "${GLFW_PREFIX}/lib")
]]
	end

	if includes.glm then
		cmake_content = cmake_content
			.. [[
# glm via homebrew
execute_process(COMMAND brew --prefix glm OUTPUT_VARIABLE GLM_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
set(GLM_INCLUDE_DIR "${GLM_PREFIX}/include")
]]
	end

	if includes.sfml then
		cmake_content = cmake_content
			.. [[
# sfml via homebrew
execute_process(COMMAND brew --prefix sfml OUTPUT_VARIABLE SFML_PREFIX OUTPUT_STRIP_TRAILING_WHITESPACE)
set(SFML_INCLUDE_DIR "${SFML_PREFIX}/include")
set(SFML_LIBRARY_DIR "${SFML_PREFIX}/lib")
]]
	end

	-- executable
	cmake_content = cmake_content .. string.format(
		[[
add_executable(game %s)

]],
		filename
	)

	-- include directories
	local include_dirs = {}
	if includes.raylib then
		table.insert(include_dirs, "${RAYLIB_INCLUDE_DIR}")
	end
	if includes.glfw then
		table.insert(include_dirs, "${GLFW_INCLUDE_DIR}")
	end
	if includes.glm then
		table.insert(include_dirs, "${GLM_INCLUDE_DIR}")
	end
	if includes.sfml then
		table.insert(include_dirs, "${SFML_INCLUDE_DIR}")
	end

	if #include_dirs > 0 then
		cmake_content = cmake_content
			.. "target_include_directories(game PRIVATE "
			.. table.concat(include_dirs, " ")
			.. ")\n"
	end

	-- library directories & linking
	local lib_dirs = {}
	local links = {}

	if includes.raylib then
		table.insert(lib_dirs, "${RAYLIB_LIBRARY_DIR}")
		table.insert(links, "raylib")
	end
	if includes.glfw then
		table.insert(lib_dirs, "${GLFW_LIBRARY_DIR}")
		table.insert(links, "glfw")
	end
	if includes.sfml then
		table.insert(lib_dirs, "${SFML_LIBRARY_DIR}")
		table.insert(links, "sfml-graphics sfml-window sfml-system sfml-audio")
	end

	if #lib_dirs > 0 then
		cmake_content = cmake_content .. "target_link_directories(game PRIVATE " .. table.concat(lib_dirs, " ") .. ")\n"
	end

	-- frameworks for raylib/glfw on macos
	if includes.raylib or includes.glfw then
		cmake_content = cmake_content
			.. [[
# macos frameworks
find_library(COREVIDEO_FRAMEWORK CoreVideo)
find_library(IOKIT_FRAMEWORK IOKit)
find_library(COCOA_FRAMEWORK Cocoa)
find_library(OPENGL_FRAMEWORK OpenGL)
]]
	end
	if includes.raylib then
		cmake_content = cmake_content .. [[
find_library(GLUT_FRAMEWORK GLUT)
]]
	end

	if #links > 0 then
		cmake_content = cmake_content .. "target_link_libraries(game " .. table.concat(links, " ")

		-- add frameworks properly
		if includes.raylib or includes.glfw then
			cmake_content = cmake_content
				.. " ${COREVIDEO_FRAMEWORK} ${IOKIT_FRAMEWORK} ${COCOA_FRAMEWORK} ${OPENGL_FRAMEWORK}"
		end
		if includes.raylib then
			cmake_content = cmake_content .. " ${GLUT_FRAMEWORK}"
		end

		cmake_content = cmake_content .. ")\n"
	end

	-- write cmake file (bulletproof)
	local cmake_path = project_root .. "/CMakeLists.txt"
	local cmake_file = io.open(cmake_path, "w")
	if cmake_file then
		cmake_file:write(cmake_content)
		cmake_file:close()
		return true
	else
		vim.notify("failed to create " .. cmake_path, vim.log.levels.ERROR)
		return false
	end
end

autocmd("BufWritePost", {
	pattern = "*.cpp",
	callback = function()
		-- wrap everything in pcall to catch errors gracefully
		local success, err = pcall(function()
			local filename = vim.fn.expand("%:t")
			local filepath = vim.fn.expand("%:p")
			local project_root = vim.fn.getcwd()

			-- validate inputs
			if not filename or filename == "" then
				vim.notify("invalid filename", vim.log.levels.WARN)
				return
			end

			if not filepath or filepath == "" then
				vim.notify("invalid filepath", vim.log.levels.WARN)
				return
			end

			local includes = detect_includes(filepath)

			-- only regen if we have external deps or no cmake exists
			local needs_cmake = false
			for _ in pairs(includes) do
				needs_cmake = true
				break
			end

			if needs_cmake or vim.fn.filereadable(project_root .. "/CMakeLists.txt") == 0 then
				if generate_cmake(project_root, filename, includes) then
					-- smart build: check for cache conflicts first
					local build_cmd = "mkdir -p build && cd build && cmake .."
					local build_result = vim.fn.system(build_cmd)

					-- if cmake failed due to cache conflict, nuke and retry
					if vim.v.shell_error ~= 0 and build_result:match("CMakeCache.txt.*different.*directory") then
						vim.notify("cmake cache conflict detected, rebuilding...", vim.log.levels.WARN)
						build_result = vim.fn.system("rm -rf build && mkdir -p build && cd build && cmake ..")
					end

					if vim.v.shell_error == 0 then
						-- vim.notify("cmake configured w/ detected libs", vim.log.levels.INFO)
						-- restart lsp only if cmake succeeded
						vim.schedule(function()
							vim.cmd("LspRestart clangd")
						end)
					else
						vim.notify("cmake configuration failed: " .. build_result, vim.log.levels.ERROR)
					end
				else
					vim.notify("failed to generate CMakeLists.txt", vim.log.levels.ERROR)
				end
			end
		end)

		if not success then
			vim.notify("autocmd error: " .. tostring(err), vim.log.levels.ERROR)
		end
	end,
})
