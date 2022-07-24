local luvibundle = require("luvibundle")

local LuviAppBundle = {
	DEFAULT_ENTRY_POINT = "main.lua",
}

function LuviAppBundle:Construct(appPath, entryPoint)
	local instance = {
		path = appPath,
		entryPoint = entryPoint or LuviAppBundle.DEFAULT_ENTRY_POINT
	}

	setmetatable(instance, { __index = LuviAppBundle })

	return instance
end

setmetatable(LuviAppBundle, {
	__call = LuviAppBundle.Construct
})

local uv = require("uv")
local luvi = require("luvi")

function LuviAppBundle:RunContainedApp(commandLineArguments)
	local bundle = assert(luvibundle.makeBundle(self.path))

	luvi.bundle = bundle

	local main = bundle:readfile(self.entryPoint)
	if not main then
		error("Entry point " .. self.entryPoint .. " does not exist in app bundle " .. bundle.base, 0)
	end

	-- It's not helpful to display the app name if we're just executing a script on disk, and would likely be misleading
	-- But for zip apps, it's less confusing to see the executable name as the files referenced won't even exist on disk
	-- This is similar to how errors appear in NodeJS, with a node: prefix (which I like better than luvit's generic bundle: prefix)
	local executableName = path.basename(uv.exepath())
	local optionalPrefix = bundle.zipReader and (executableName .. ":" ) or ""
	-- @ option = render error message with <file name>:, not the generic ["string ..."] prefix, which is far less readable
	local compiledScriptChunk = assert(loadstring(main, "@"  .. optionalPrefix .. self.entryPoint))

	local function exportScriptGlobals()
		local cwd = uv.cwd()

		_G.DEFAULT_USER_SCRIPT_ENTRY_POINT = "main.lua"
		local scriptFile = commandLineArguments[1] or _G.DEFAULT_USER_SCRIPT_ENTRY_POINT

		local scriptPath = path.resolve(path.join(cwd, scriptFile))
		local scriptRoot = path.dirname(scriptPath)

		-- These will never change over the course of a single invocation, so it's safe to simply export them once
		_G.USER_SCRIPT_FILE = path.basename(scriptFile)
		_G.USER_SCRIPT_PATH = scriptPath
		_G.USER_SCRIPT_ROOT = scriptRoot
	end

	exportScriptGlobals()
	return compiledScriptChunk(unpack(commandLineArguments))
end

function LuviAppBundle:CreateZipApp(outputPath)
	return luvibundle.buildBundle(outputPath, luvibundle.makeBundle(self.path))
end

return LuviAppBundle