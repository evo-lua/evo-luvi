local miniz = require("miniz")
local uv = require("uv")

local luvi = require("luvi")
local luvipath = require("luvipath")
local luvibundle = require("luvibundle")
local path_join = luvipath.pathJoin

local PosixFileSystemMixin = require("PosixFileSystemMixin")
local ZipFileSystemMixin = require("ZipFileSystemMixin")

local LuviAppBundle = {
	DEFAULT_ENTRY_POINT = "main.lua",
}

function LuviAppBundle:Construct(appPath, entryPoint)
	local instance = {
		path = appPath,
		entryPoint = entryPoint or LuviAppBundle.DEFAULT_ENTRY_POINT
	}

	setmetatable(instance, { __index = LuviAppBundle })

	local path = path_join(uv.cwd(), appPath)
	instance.base = path
	instance.zipReader = miniz.new_reader(path) -- Can be nil for POSIX bundles, but that's working as intended

	if instance.zipReader then
		mixin(instance, ZipFileSystemMixin)

		local topLevelDirectory = instance:getRootDirectory()
		if topLevelDirectory then
			instance:chroot(topLevelDirectory .. "/")
		end

		return instance
	end

	local stat = uv.fs_stat(path)
	if not stat then
		error(string.format("Failed to load %s (No such file exists)", path), 0)
	elseif stat.type ~= "directory" then
		error(string.format("Failed to load %s (Unsupported file type)", path), 0)
	end

	mixin(instance, PosixFileSystemMixin)

	return instance
end

setmetatable(LuviAppBundle, {
	__call = LuviAppBundle.Construct
})

function LuviAppBundle:RunContainedApp(commandLineArguments)
	luvi.bundle = self

	local main = self:readfile(self.entryPoint)
	if not main then
		error("Entry point " .. self.entryPoint .. " does not exist in app bundle " .. self.base, 0)
	end

	-- It's not helpful to display the app name if we're just executing a script on disk, and would likely be misleading
	-- But for zip apps, it's less confusing to see the executable name as the files referenced won't even exist on disk
	-- This is similar to how errors appear in NodeJS, with a node: prefix (which I like better than luvit's generic bundle: prefix)
	local executableName = path.basename(uv.exepath())
	local optionalPrefix = self.zipReader and (executableName .. ":" ) or ""
	-- @ option = render error message with <file name>:, not the generic ["string ..."] prefix, which is far less readable
	local compiledScriptChunk = assert(loadstring(main, "@"  .. optionalPrefix .. self.entryPoint))

	self:ExportScriptGlobals(commandLineArguments)
	return compiledScriptChunk(unpack(commandLineArguments))
end

-- This is tied to the import logic (bad...); it urgently needs a rework and more tests. Until then: DNT!
function LuviAppBundle:ExportScriptGlobals(commandLineArguments)
	local cwd = uv.cwd()

	_G.DEFAULT_USER_SCRIPT_ENTRY_POINT = self.DEFAULT_ENTRY_POINT
	local scriptFile = commandLineArguments[1] or _G.DEFAULT_USER_SCRIPT_ENTRY_POINT

	local scriptPath = path.resolve(path.join(cwd, scriptFile))
	local scriptRoot = path.dirname(scriptPath)

	-- These will never change over the course of a single invocation, so it's safe to simply export them once
	_G.USER_SCRIPT_FILE = path.basename(scriptFile)
	_G.USER_SCRIPT_PATH = scriptPath
	_G.USER_SCRIPT_ROOT = scriptRoot
end

function LuviAppBundle:CreateZipApp(outputPath)
	return luvibundle.buildBundle(outputPath, self)
end

return LuviAppBundle