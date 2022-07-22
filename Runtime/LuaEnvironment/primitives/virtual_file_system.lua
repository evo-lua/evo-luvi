-- Upvalues
local loadstring = loadstring

-- High-level wrapper for Luvi's builtin bundling API (virtual file system)
-- This allows the higher-level APIs to tap into Luvi's bundling functionality with a clearer interface, abstracting some low-level calls
local vfs = {}

function vfs.hasFile(filePath)
	local bundle = vfs.getBundle()
	local fileStats = bundle.stat(filePath)
	if fileStats and fileStats.type == "file" then
		return true
	end
end

function vfs.hasFolder(filePath)
	local bundle = vfs.getBundle()
	local fileStats = bundle.stat(filePath)
	if fileStats and fileStats.type == "directory" then
		return true
	end
end

function vfs.loadFile(filePath)
	local bundle = vfs.getBundle()
	local fileContents = bundle.readfile(filePath)
	local compiledChunk = loadstring(fileContents)()
	return compiledChunk
end

function vfs.getBundle()
	-- Defer loading since it won't be available when this module is first compiled
	local luvi = require("luvi")
	return luvi.bundle
end

return vfs
