-- Lua doesn't automatically search subdirectories, so we have to teach it where to find the modules
package.path = package.path .. ";API/?.lua;API/?/?.lua;"

local namespaceLoaders = {
	C_Testing = function()
		return require("C_Testing")
	end,
	C_EventSystem = function()
		return require("C_EventSystem")
	end,
	C_FileSystem = function()
		return require("C_FileSystem")
	end,
	C_Networking = function()
		return require("C_Networking")
	end,
}

return namespaceLoaders
