-- Lua doesn't automatically search subdirectories, so we have to teach it where to find the modules
package.path = package.path .. ";extensions/?.lua;"

-- Since they may depend on primitives that aren't yet preloaded, defer the loading process
local extensionLoaders = {
	-- Nonstandard libraries
	path = function() return require("path") end,
}

return extensionLoaders