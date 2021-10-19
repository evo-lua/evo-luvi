
local uv = require("uv")
local vfs = require("virtual_file_system")

-- TODO Move test to evo-luvi and use the existing assertion utilities
-- TODO Add CI workflow for this test

local moduleCache = {}
local prefixStack = {}

local EPO_PACKAGE_DIRECTORY = ".epo"

_G.rootDirectory = uv.cwd() -- tbd: find a better way to do this? OR just embrace it and introduce a global SCRIPT_ROOT or sth?

local function import(modulePath)
	-- print("Dumping prefix stack...")
	-- dump(prefixStack)

	if type(modulePath) ~= "string" or modulePath == "" or modulePath == "@" then
		return nil, "Usage: import(modulePath)"
	end

	local isEpoPackage = false
	if string.sub(modulePath, 1, 1) == "@" then
		print("Detected epo package notation identifier (@)")
		local strippedModulePath = string.sub(modulePath, 2)
		modulePath = path.join(EPO_PACKAGE_DIRECTORY, strippedModulePath)
		print("Module path is now: " .. modulePath)
		isEpoPackage = true
	end

	if path.extname(modulePath) ~= ".lua" then
		print("Attempted to import module path without extension; assuming .lua")
		if isEpoPackage then
			-- Assume entry point is main.lua, if none was given
			print("No epo module entry point was given, assuming main.lua")
			modulePath = path.join(modulePath, "main.lua")
		else
			modulePath = modulePath .. ".lua"
		end
		print("Module path is now: " .. modulePath)
	end

	local cwd = uv.cwd()
	local scriptFile = args[1] or "main.lua" -- Will include the .. operator if it isn't the bundle's root file (on disk)
	local scriptPath = path.resolve(path.join(cwd, scriptFile)) -- Remove the operators if they're present

	-- print("Source: " .. source)
	print("Script file: " .. scriptFile)
	print("Script path: " .. scriptPath)

	-- If no parent chain existed, use the main entry point instead
	local entryPoint = path.resolve(path.join(cwd, scriptFile)) -- TBD: Why is it the same as scriptPath?
	print("Detected entry point: " .. entryPoint)
	local parentModule = (#prefixStack == 0) and entryPoint or prefixStack[#prefixStack] -- It must be the entry point (top-level module)
	_G.rootDirectory = path.dirname(entryPoint) -- Only needed for the assertion below, so this is somewhat awkward

	local parentDirectory = path.dirname(parentModule)
	local absolutePath = path.resolve(path.join(parentDirectory, modulePath))

	print("Importing from path: " .. path.join(parentDirectory, modulePath))
	print("Resolved to: " .. absolutePath)

	print("Parent directory for this import: " .. parentDirectory)

	-- The bundle VFS always takes priority, so check it first
	print("Parent module: " .. parentModule)
	local relativeModulePath = path.relative(scriptPath, modulePath)
	print("Relative path (used for bundle lookups): " .. relativeModulePath)

	local cachedModule = moduleCache[absolutePath]
	if cachedModule then
		-- Nested imports can't happen here, so we don't need to update the prefix stack
		print("Returning from module cache...")
		return cachedModule, absolutePath, parentModule
	end

	-- By always pushing the latest prefix before loading, the context can be reconstructed from inside the nested import call
	prefixStack[#prefixStack+1] = absolutePath

	-- print("Dumping prefix stack...")
	-- dump(prefixStack)

	local loadedModule = {}
	if vfs.hasFile(modulePath) then
		print("Loading from the bundle's virtual file system (file): " .. modulePath)
		loadedModule = vfs.loadFile(modulePath), path.resolve(path.join(cwd, modulePath)), parentModule
	elseif vfs.hasFolder(path.join(EPO_PACKAGE_DIRECTORY, modulePath)) then
		modulePath = path.join(EPO_PACKAGE_DIRECTORY, modulePath, "main.lua")
		print("Loading from the bundle's virtual file system (folder): " .. modulePath)
		loadedModule = vfs.loadFile(modulePath), path.resolve(path.join(cwd, modulePath)), parentModule
	else
		print("Loading from disk...")
		loadedModule = dofile(absolutePath)
	end

	if (#prefixStack > 0) then
		-- This must be a nested call, so we want to clear out the parent hierarchy before exiting
		local removedParent = table.remove(prefixStack)
		print("Removed parent element from prefix stack: " .. removedParent)
	end

	print("Cached new module: " .. absolutePath)
	moduleCache[absolutePath] = loadedModule

	return loadedModule, absolutePath, parentModule
end

return import
