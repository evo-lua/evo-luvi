local luvi = require("luvi")
local bundle = luvi.bundle

-- Upvalues
local loadstring = loadstring

-- High-level wrapper for Luvi's builtin bundling API (virtual file system)
-- This allows the higher-level APIs to tap into Luvi's bundling functionality with a clearer interface, abstracting some low-level calls
local vfs = {}

function vfs.hasFile(filePath)
	local fileStats = bundle.stat(filePath)
	if fileStats and fileStats.type == "file" then
		return true
	end
end

function vfs.hasFolder(filePath)
	local fileStats = bundle.stat(filePath)
	if fileStats and fileStats.type == "directory" then
		return true
	end
end

function vfs.loadFile(filePath)
	local fileContents = bundle.readfile(filePath)
	local compiledChunk = loadstring(fileContents)()
	return compiledChunk
end

return vfs
