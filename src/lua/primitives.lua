-- Lua doesn't automatically search subdirectories, so we have to teach it where to find the modules
package.path = package.path .. ";primitives/?.lua;"

-- Primitives (need to be loaded first, as libaries may depend on them)
local primitives = {
	["v8_string_helpers"] = require("v8_string_helpers"),
	["virtual_file_system"] = require("virtual_file_system"),
}

return primitives