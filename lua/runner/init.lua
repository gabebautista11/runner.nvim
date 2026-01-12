local runnerFile = ""
local keys = {}

function ReadJsonRunnerFile()
	local file = io.open("runner.json", "r")
	if file == nil then
		error("runner.json file cannot be found")
	else
		local json = file:read("*a")
		file:close()
		return json
	end
end

function GetKeys()
	local json = require("json")
	local jsonFile = ReadJsonRunnerFile()
	local jsonObject = json.decode(jsonFile)
	local jsonKeys = {}
	for k, v in pairs(jsonObject) do
		table.insert(jsonKeys, k)
	end
	return jsonKeys
end

function RunCommand(jsonKey)
	local json = require("json")
	local jsonFile = ReadJsonRunnerFile()
end

function setup_autocmds()
	vim.api.nvim_create_autocmd("CmdlineEnter", {
		callback = function()
			runnerFile = ReadJsonRunnerFile()
			keys = GetKeys()
		end,
	})
end
