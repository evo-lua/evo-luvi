
-- Imports
local uv = require("uv")
local vfs = require("virtual_file_system")

-- Exports
_G.EVO_PACKAGE_DIRECTORY = ".evo"
_G.ENABLE_IMPORT_DEBUGGING = false -- Can just enable it globally to debug imports, in lieu of better logging capabilities...

-- Upvalues
local dofile = dofile
local type = type
local string_sub = string.sub
local table_remove = table.remove
-- Can't cache them yet, but we do want to speed up access so we add them to the closure
local path_join
local path_resolve
local path_dirname
local path_extname

-- Locals
local moduleCache = {}
local prefixStack = {}

-- Needs a proper logging framework, but for now it'll do...
local print = function(...)
	if not _G.ENABLE_IMPORT_DEBUGGING then return end
	print(...)
end

local function cachePathModule()
	print("Caching path library to speed up future lookups... This should only happen once!")

	-- If this breaks, all bets are off... so I guess adding a more specific error message might help troubleshooting?
	assert(type(path) == "table", "The required path module is not available (this should never happen")

	path_join = path.join
	path_resolve = path.resolve
	path_dirname = path.dirname
	path_extname = path.extname
end

-- Expose internals for easier debugging
_G.EVO_IMPORT_CACHE = moduleCache
_G.EVO_IMPORT_STACK = prefixStack
local function import(modulePath)

	-- Caching for future lookups isn't possible at initialization, as the path module may not be loaded yet
	if not path_join then
		cachePathModule()
	end

	if type(modulePath) ~= "string" or modulePath == "" or modulePath == "@" then
		return nil, "Usage: import(modulePath)"
	end

	local isEvoPackage = false
	if string_sub(modulePath, 1, 1) == "@" then
		print("Detected evo package notation identifier (@)")
		local strippedModulePath = string_sub(modulePath, 2)
		modulePath = path_join(EVO_PACKAGE_DIRECTORY, strippedModulePath)
		print("Module path is now: " .. modulePath)
		isEvoPackage = true
	end

	if path_extname(modulePath) ~= ".lua" then
		print("Attempted to import module path without extension; assuming .lua")
		if isEvoPackage then
			-- Assume entry point is the default one, if none was given
			print("No evo module entry point was given, assuming default of " .. _G.DEFAULT_USER_SCRIPT_ENTRY_POINT)
			modulePath = path_join(modulePath, _G.DEFAULT_USER_SCRIPT_ENTRY_POINT)
		else
			modulePath = modulePath .. ".lua"
		end
		print("Module path is now: " .. modulePath)
	end

	-- If no parent chain existed, use the main entry point instead
	local parentModule = (#prefixStack == 0) and USER_SCRIPT_PATH or prefixStack[#prefixStack]

	local parentDirectory = path_dirname(parentModule)
	local unresolvedModulePath = path_join(parentDirectory, modulePath)
	local absolutePath = path_resolve(unresolvedModulePath)

	print("Importing from path: " .. unresolvedModulePath)
	print("Resolved to: " .. absolutePath)
	print("Parent module: " .. parentModule)
	print("Parent directory for this import: " .. parentDirectory)

	-- The bundle VFS always takes priority, so check it first
	local cachedModule = moduleCache[absolutePath]
	if cachedModule then
		-- Nested imports can't happen here, so we don't need to update the prefix stack
		print("Returning from module cache...")
		return cachedModule, absolutePath, parentModule
	end

	-- By always pushing the latest prefix before loading, the context can be reconstructed from inside nested import calls
	prefixStack[#prefixStack+1] = absolutePath

	local loadedModule
	if vfs.hasFile(modulePath) then
		print("Loading from the bundle's virtual file system (file): " .. modulePath)
		loadedModule = vfs.loadFile(modulePath)
	elseif vfs.hasFolder(path_join(EVO_PACKAGE_DIRECTORY, modulePath)) then
		modulePath = path_join(EVO_PACKAGE_DIRECTORY, modulePath, "main.lua")
		print("Loading from the bundle's virtual file system (folder): " .. modulePath)
		loadedModule = vfs.loadFile(modulePath)
	else
		print("Loading from disk:" .. absolutePath)
		loadedModule = dofile(absolutePath)
	end

	if (#prefixStack > 0) then
		-- This must be a nested call, so we want to clear out the parent hierarchy before exiting
		local removedParent = table_remove(prefixStack)
		print("Removed parent element from prefix stack: " .. removedParent)
	end

	print("Cached new module: " .. absolutePath)
	moduleCache[absolutePath] = loadedModule

	return loadedModule, absolutePath, parentModule
end

return import
