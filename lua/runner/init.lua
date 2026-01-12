-- Read JSON runner.json file in current directory opened

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

keys = GetKeys()
