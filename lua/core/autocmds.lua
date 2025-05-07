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

-- god-tier cpp intellisense injector
-- generates compile_commands.json on save for cpp files
autocmd("BufWritePost", {
	pattern = "*.cpp",
	callback = function()
		local filename = vim.fn.expand("%:t") -- Get filename with extension
		local full_path = vim.fn.expand("%:p") -- Full path with filename
		local project_root = vim.fn.getcwd()

		-- scan for includes
		local file = io.open(full_path, "r")
		local includes = {}
		if file then
			for line in file:lines() do
				if line:match("^%s*#include") then
					table.insert(includes, line)
				end
			end
			file:close()
		end

		-- detect if we need to update compile_commands.json
		local needs_update = true
		local compile_commands_path = project_root .. "/compile_commands.json"
		local compile_file = io.open(compile_commands_path, "r")

		if compile_file then
			local content = compile_file:read("*all")
			compile_file:close()

			-- check if all current includes are covered
			local update_required = false
			for _, include in ipairs(includes) do
				if include:match("<raylib.h>") and not content:match("raylib") then
					update_required = true
					break
				elseif include:match("<glm/") and not content:match("glm") then
					update_required = true
					break
				elseif include:match("<GLFW/") and not content:match("glfw") then
					-- added GLFW detection
					update_required = true
					break
				end
			end

			needs_update = update_required
		end

		-- generate compile_commands.json if needed
		if needs_update then
			-- get include paths programatically
			local raylib_includes = vim.fn.system("echo -I$(brew --prefix raylib)/include"):gsub("\n", "")
			local glm_includes = vim.fn.system("echo -I$(brew --prefix glm)/include"):gsub("\n", "")
			local glfw_includes = vim.fn.system("echo -I$(brew --prefix glfw)/include"):gsub("\n", "")

			local compile_commands = string.format(
				[[
[
  {
    "directory": "%s",
    "command": "g++ -std=c++17 %s %s %s -I/usr/local/include %s -o game",
    "file": "%s"
  }
]
      ]],
				project_root,
				raylib_includes,
				glm_includes,
				glfw_includes,
				filename,
				filename
			)

			local out_file = io.open(compile_commands_path, "w")
			if out_file then
				out_file:write(compile_commands)
				out_file:close()
				vim.notify("compile_commands.json updated with GLFW support", vim.log.levels.INFO)

				-- force lsp refresh
				vim.cmd("LspRestart clangd")
			end
		end
	end,
})
