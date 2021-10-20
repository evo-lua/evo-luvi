-- Lua doesn't automatically search subdirectories, so we have to teach it where to find the modules
package.path = package.path .. ";primitives/?.lua;"

-- Primitives (need to be loaded first, as libaries may depend on them)
local primitives = {
	-- @deprecated: Use v8_string in new code
	["v8_string_helpers"] = function() return require("v8_string") end,
	["virtual_file_system"] = function() return require("virtual_file_system") end,
}

return primitives