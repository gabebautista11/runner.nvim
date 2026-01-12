-- lua/project_runner/init.lua
local M = {}

local keys = {}
local merged = {}

-- Read all runner.json paths recursively from cwd
local function find_all_runner_files()
	return vim.fs.find("runner.json", {
		type = "file",
		limit = math.huge,
		path = vim.fn.getcwd(), -- project root
	})
end

-- Load & merge all JSON files into one table
local function load_and_merge_runner_files()
	local json = require("json")
	local result = {}

	for _, path in ipairs(find_all_runner_files()) do
		local file = io.open(path, "r")
		if not file then
			vim.notify("Failed to open " .. path, vim.log.levels.ERROR)
		else
			local raw = file:read("*a")
			file:close()

			local ok, obj = pcall(json.decode, raw)
			if not ok then
				vim.notify("JSON decode failed in " .. path, vim.log.levels.ERROR)
			elseif type(obj) == "table" then
				for k, v in pairs(obj) do
					if result[k] then
						vim.notify(("Duplicate key '%s' overridden from %s"):format(k, path), vim.log.levels.WARN)
					end
					result[k] = v
				end
			end
		end
	end

	return result
end

-- Refresh data + keys list
local function refresh_runner_data()
	merged = load_and_merge_runner_files()
	keys = {}

	for k, _ in pairs(merged) do
		table.insert(keys, k)
	end

	vim.notify("runner.json reloaded (" .. #keys .. " modes found)")
end

-- Public command (optional)
local function setup_commands()
	vim.api.nvim_create_user_command("RunMode", function(opts)
		local mode = opts.args
		local cmd = merged[mode]

		if not cmd then
			vim.notify("Mode '" .. mode .. "' not found", vim.log.levels.ERROR)
			return
		end

		vim.notify("Running: " .. cmd)

		-- spawn in a terminal
		vim.cmd("split | terminal " .. cmd)
	end, {
		nargs = 1,
		complete = function()
			return keys
		end,
	})
end

-- Autocmd reload on write
local function setup_autocmds()
	vim.api.nvim_create_autocmd("BufWritePost", {
		pattern = "**/runner.json",
		callback = refresh_runner_data,
	})

	-- load immediately on startup
	vim.api.nvim_create_autocmd("VimEnter", {
		callback = refresh_runner_data,
	})
end

function M.setup()
	setup_autocmds()
	setup_commands()
end

return M
