-- Lua doesn't automatically search subdirectories, so we have to teach it where to find the modules
package.path = package.path .. ";extensions/?.lua;"

-- Since they may depend on primitives that aren't yet preloaded, defer the loading process
local extensionLoaders = {
	dump = function()
		return require("dump")
	end,
	-- Nonstandard libraries
	path = function()
		return require("path")
	end,
	import = function()
		return require("import")
	end,
	mixin = function()
		return require("mixin")
	end,
}

return extensionLoaders
