local function isLuaFile(filePath)
	return path.extname(filePath) == ".lua"
end

local green = transform.green
local red = transform.red

local function scanLuaFile(filePath)
	-- Buffering the entire file isn't an issue since they won't be very large
	local fileContents = C_FileSystem.ReadFile(filePath)
	local headerComment = string.match(fileContents, "@CONCERNS: (.-)\n")

	if not headerComment then
		print(red("WARNING: No SRP header found in " .. filePath))
		return
	end

	print(green(format("OK\t%s\t%s", filePath, headerComment)))
end

local uv = require("uv")
local sourceDir = path.join(uv.cwd(), "Runtime")
local files = C_FileSystem.ReadDirectory(sourceDir, true)

for filePath in pairs(files) do
	if isLuaFile(filePath) then
		scanLuaFile(filePath)
	else
		-- print("SKIPPING " .. filePath .. " (not a Lua script)... ")
	end
end

-- dump(files)