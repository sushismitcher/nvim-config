-- arduino port auto-detection + auto-compile
-- runs when you open nvim in a project with .arduino-project
-- watches for new usb ports and updates the project file automatically
-- compiles on save in background terminal buffer

local M = {}

-- terminal buffer for compile output
M.compile_buf = nil
M.compile_win = nil
M.last_compile_hash = nil

local function get_tty_ports()
	local handle = io.popen("ls /dev/tty.* 2>/dev/null")
	if not handle then
		return {}
	end
	local result = handle:read("*a")
	handle:close()

	local ports = {}
	for port in result:gmatch("[^\n]+") do
		table.insert(ports, port)
	end
	return ports
end

local function read_arduino_project()
	local project_file = vim.fn.getcwd() .. "/.arduino-project"
	if vim.fn.filereadable(project_file) == 0 then
		return nil
	end

	local lines = vim.fn.readfile(project_file)
	local config = {}
	for _, line in ipairs(lines) do
		local key, value = line:match("^(.-)=(.*)$")
		if key then
			config[key] = value
		end
	end
	return config
end

local function write_arduino_project(config)
	local project_file = vim.fn.getcwd() .. "/.arduino-project"
	local lines = {}
	for key, value in pairs(config) do
		table.insert(lines, key .. "=" .. value)
	end
	vim.fn.writefile(lines, project_file)
end

local function find_new_port(old_ports, new_ports)
	for _, new_port in ipairs(new_ports) do
		local is_new = true
		for _, old_port in ipairs(old_ports) do
			if new_port == old_port then
				is_new = false
				break
			end
		end
		if is_new then
			return new_port
		end
	end
	return nil
end

local function is_arduino_project()
	return vim.fn.filereadable(vim.fn.getcwd() .. "/.arduino-project") == 1
end

local function get_ino_file()
	local files = vim.fn.glob("*.ino", false, true)
	return files[1] -- return first .ino file
end

function M.compile(on_complete)
	if not is_arduino_project() then
		if on_complete then
			on_complete(false)
		end
		return
	end

	local config = read_arduino_project()
	if not config or not config.fqbn then
		if on_complete then
			on_complete(false)
		end
		return
	end

	-- get current buffer content and hash it
	local bufnr = vim.api.nvim_get_current_buf()
	local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
	local content = table.concat(lines, "\n")
	local hash = vim.fn.sha256(content)

	-- skip if content hasn't changed - but still call callback with success
	if hash == M.last_compile_hash then
		if on_complete then
			on_complete(true)
		end
		return
	end
	M.last_compile_hash = hash

	-- create buffer if doesn't exist
	if not M.compile_buf or not vim.api.nvim_buf_is_valid(M.compile_buf) then
		M.compile_buf = vim.api.nvim_create_buf(false, true) -- unlisted, scratch
		vim.api.nvim_buf_set_option(M.compile_buf, "bufhidden", "hide")
		vim.api.nvim_buf_set_option(M.compile_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(M.compile_buf, "buflisted", false)
		vim.api.nvim_buf_set_option(M.compile_buf, "swapfile", false)
	end

	-- clear previous output
	vim.api.nvim_buf_set_lines(M.compile_buf, 0, -1, false, { "compiling..." })

	-- run compile with jobstart
	local compile_cmd = string.format("arduino-cli compile --fqbn %s .", config.fqbn)

	vim.fn.jobstart(compile_cmd, {
		cwd = vim.fn.getcwd(),
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(M.compile_buf, -1, -1, false, data)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(M.compile_buf, -1, -1, false, data)
			end
		end,
		on_exit = function(_, exit_code)
			local status = exit_code == 0 and "✓ compile success" or "✗ compile failed"
			vim.api.nvim_buf_set_lines(M.compile_buf, -1, -1, false, { "", status })
			if on_complete then
				on_complete(exit_code == 0)
			end
		end,
	})
end

function M.upload()
	if not is_arduino_project() then
		vim.notify("not an arduino project", vim.log.levels.ERROR)
		return
	end

	local config = read_arduino_project()
	if not config or not config.fqbn or not config.port then
		vim.notify("missing fqbn or port in .arduino-project", vim.log.levels.ERROR)
		return
	end

	if config.port == "" then
		vim.notify("no port detected - run arduino detect or plug in board", vim.log.levels.WARN)
		return
	end

	-- verify port still exists
	local port_exists = vim.fn.filereadable(config.port) == 1
	if not port_exists then
		vim.notify("port " .. config.port .. " not found - board disconnected?", vim.log.levels.ERROR)
		return
	end

	-- create buffer if doesn't exist
	if not M.compile_buf or not vim.api.nvim_buf_is_valid(M.compile_buf) then
		M.compile_buf = vim.api.nvim_create_buf(false, true)
		vim.api.nvim_buf_set_option(M.compile_buf, "bufhidden", "hide")
		vim.api.nvim_buf_set_option(M.compile_buf, "buftype", "nofile")
		vim.api.nvim_buf_set_option(M.compile_buf, "buflisted", false)
		vim.api.nvim_buf_set_option(M.compile_buf, "swapfile", false)
	end

	-- clear and show upload start
	vim.api.nvim_buf_set_lines(M.compile_buf, 0, -1, false, {
		"uploading to " .. config.port .. "...",
		"",
	})

	-- upload using arduino-cli
	local upload_cmd = string.format("arduino-cli upload -p %s --fqbn %s .", config.port, config.fqbn)

	vim.notify("uploading to " .. config.port .. "...", vim.log.levels.INFO)

	vim.fn.jobstart(upload_cmd, {
		cwd = vim.fn.getcwd(),
		stdout_buffered = false,
		stderr_buffered = false,
		on_stdout = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(M.compile_buf, -1, -1, false, data)
			end
		end,
		on_stderr = function(_, data)
			if data then
				vim.api.nvim_buf_set_lines(M.compile_buf, -1, -1, false, data)
			end
		end,
		on_exit = function(_, exit_code)
			local status = exit_code == 0 and "✓ upload complete"
				or "✗ upload failed (exit code: " .. exit_code .. ")"
			vim.api.nvim_buf_set_lines(M.compile_buf, -1, -1, false, { "", status })

			if exit_code == 0 then
				vim.notify("✓ upload complete", vim.log.levels.INFO)
			else
				vim.notify("✗ upload failed - check output with <leader>j", vim.log.levels.ERROR)
			end
		end,
	})
end

function M.compile_and_upload()
	-- save first
	vim.cmd("write")

	-- compile then upload
	M.compile(function(success)
		if success then
			M.upload()
		else
			vim.notify("compile failed - not uploading", vim.log.levels.ERROR)
		end
	end)
end

function M.toggle_compile_output()
	if not M.compile_buf or not vim.api.nvim_buf_is_valid(M.compile_buf) then
		vim.notify("no compile output yet", vim.log.levels.INFO)
		return
	end

	-- check if buffer is visible in any window
	local buf_visible = false
	for _, win in ipairs(vim.api.nvim_list_wins()) do
		if vim.api.nvim_win_get_buf(win) == M.compile_buf then
			buf_visible = true
			M.compile_win = win
			break
		end
	end

	if buf_visible then
		-- hide it
		vim.api.nvim_win_close(M.compile_win, false)
		M.compile_win = nil
	else
		-- show it in horizontal split
		vim.cmd("split")
		M.compile_win = vim.api.nvim_get_current_win()
		vim.api.nvim_win_set_buf(M.compile_win, M.compile_buf)
		vim.api.nvim_win_set_height(M.compile_win, 15)

		-- scroll to bottom
		vim.schedule(function()
			local line_count = vim.api.nvim_buf_line_count(M.compile_buf)
			vim.api.nvim_win_set_cursor(M.compile_win, { line_count, 0 })
		end)

		-- go back to previous window
		vim.cmd("wincmd p")
	end
end

function M.setup()
	local config = read_arduino_project()
	if not config then
		return -- not an arduino project
	end

	-- set up auto-compile on save
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "*.ino",
		callback = function()
			M.compile()
		end,
	})

	-- auto-close compile window when it would be left alone
	vim.api.nvim_create_autocmd({ "QuitPre", "BufDelete" }, {
		callback = function()
			-- if compile window is open and would be the only window left, close it
			if M.compile_win and vim.api.nvim_win_is_valid(M.compile_win) then
				local normal_wins = 0
				for _, win in ipairs(vim.api.nvim_list_wins()) do
					local buf = vim.api.nvim_win_get_buf(win)
					local buftype = vim.api.nvim_buf_get_option(buf, "buftype")
					if buftype == "" then -- normal buffer
						normal_wins = normal_wins + 1
					end
				end

				-- if only 1 or 0 normal windows left, close compile window
				if normal_wins <= 1 then
					pcall(vim.api.nvim_win_close, M.compile_win, true)
					M.compile_win = nil
				end
			end
		end,
	})

	-- compile on startup (small delay to let file load)
	vim.defer_fn(function()
		M.compile()
	end, 100)

	-- port detection timer
	local initial_ports = get_tty_ports()
	local start_time = vim.loop.now()
	local max_wait = 60000 -- 1 minute in milliseconds
	local check_interval = 2000 -- check every 2 seconds

	local timer = vim.loop.new_timer()
	timer:start(
		check_interval,
		check_interval,
		vim.schedule_wrap(function()
			local elapsed = vim.loop.now() - start_time

			-- stop after 1 minute
			if elapsed >= max_wait then
				timer:stop()
				timer:close()

				-- alert if port still empty
				if config.port == "" then
					vim.notify("no valid port found", vim.log.levels.WARN)
				end
				return
			end

			local current_ports = get_tty_ports()
			local new_port = find_new_port(initial_ports, current_ports)

			if new_port then
				-- found new port, update project file
				config.port = new_port
				write_arduino_project(config)
				vim.notify("detected port: " .. new_port, vim.log.levels.INFO)

				-- stop checking
				timer:stop()
				timer:close()
			end
		end)
	)
end

return M
