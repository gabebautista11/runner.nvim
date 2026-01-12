-- lua/project_runner/init.lua
local M = {}

local keys = {}
local merged = {}

-----------------------------------------------------------
-- Find all runner.json files recursively from cwd
-----------------------------------------------------------
local function find_all_runner_files()
	return vim.fs.find("runner.json", {
		type = "file",
		limit = math.huge,
		path = vim.fn.getcwd(), -- project root
	})
end

-----------------------------------------------------------
-- Load & merge JSON files into one config table
-----------------------------------------------------------
local function load_and_merge_runner_files()
	local result = {}

	for _, path in ipairs(find_all_runner_files()) do
		local file = io.open(path, "r")
		if file then
			local raw = file:read("*a")
			file:close()
			local ok, obj = pcall(vim.fn.json_decode, raw)
			if ok and type(obj) == "table" then
				for k, v in pairs(obj) do
					if result[k] then
						vim.notify(("Duplicate key '%s' overridden from %s"):format(k, path), vim.log.levels.WARN)
					end
					result[k] = v
				end
			else
				vim.notify("JSON decode failed in " .. path, vim.log.levels.ERROR)
			end
		else
			vim.notify("Failed to open " .. path, vim.log.levels.ERROR)
		end
	end

	return result
end

-----------------------------------------------------------
-- Rebuild merged + keys list
-----------------------------------------------------------
local function refresh_runner_data()
	merged = load_and_merge_runner_files()
	keys = {}

	for k, _ in pairs(merged) do
		keys[#keys + 1] = k -- packed array
	end

	vim.notify("runner.json loaded (" .. #keys .. " keys)", vim.log.levels.INFO)
end

-----------------------------------------------------------
-- :Run command with completion
-----------------------------------------------------------
local function setup_commands()
	vim.api.nvim_create_user_command("Run", function(opts)
		local mode = opts.args
		local cmd = merged[mode]

		if not cmd then
			vim.notify("Mode '" .. mode .. "' not found", vim.log.levels.ERROR)
			return
		end

		-- Open a new buffer in a split (optional)
		vim.cmd("new") -- or "vnew" for vertical split, or just use current window

		-- Get the current buffer (this will be replaced by term buffer)
		local buf = vim.api.nvim_get_current_buf()

		-- Start the terminal in this buffer (termopen creates the terminal buffer)
		vim.fn.termopen(cmd)

		-- Rename the buffer after the mode
		local term_buf = vim.api.nvim_get_current_buf()
		vim.api.nvim_buf_set_name(term_buf, "Runner: " .. mode)

		-- Enter insert mode for interactive terminal
		vim.cmd("startinsert")
	end, {
		nargs = 1,
		complete = function()
			local items = {}
			for _, key in ipairs(keys) do
				items[#items + 1] = key
			end
			return items
		end,
	})
end

-----------------------------------------------------------
-- Auto-load when Neovim starts + reload on runner.json write
-----------------------------------------------------------
local function setup_autocmds()
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "**/runner.json",
		callback = refresh_runner_data,
	})

	vim.api.nvim_create_autocmd("VimEnter", {
		callback = refresh_runner_data,
	})
end

-----------------------------------------------------------
-- Public setup
-----------------------------------------------------------
function M.setup()
	setup_autocmds()
	setup_commands()
	refresh_runner_data() -- ensure keys exist if VimEnter missed
end

-----------------------------------------------------------
-- Optional debugging accessor
-----------------------------------------------------------
function M.debug_keys()
	return keys
end

return M
