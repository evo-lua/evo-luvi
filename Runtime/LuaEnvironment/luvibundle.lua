local uv = require("uv")
local miniz = require("miniz")
local luvi = require("luvi")
local luviPath = require("luvipath")
local pathJoin = luviPath.pathJoin

local loadstring = loadstring or load
local unpack = unpack or _G.table.unpack

local hiddenFilesAllowList = {
	[".evo"] = true, -- Always include evo packages in compiled bundles or import won't work
}

local function buildBundle(target, bundle)
	target = pathJoin(uv.cwd(), target)
	print("Creating new binary: " .. target)
	local fd = assert(uv.fs_open(target, "w", 511)) -- 0777
	local binSize
	do
		local source = uv.exepath()

		local reader = miniz.new_reader(source)
		if reader then
			-- If contains a zip, find where the zip starts
			binSize = reader:get_offset()
		else
			-- Otherwise just read the file size
			binSize = uv.fs_stat(source).size
		end
		local fd2 = assert(uv.fs_open(source, "r", 384)) -- 0600
		print("Copying initial " .. binSize .. " bytes from " .. source)
		uv.fs_sendfile(fd, fd2, 0, binSize)
		uv.fs_close(fd2)
	end

	local writer = miniz.new_writer()
	local function copyFolder(path)
		local files = bundle:readdir(path)
		if not files then
			return
		end
		for i = 1, #files do
			local name = files[i]
			if string.sub(name, 1, 1) ~= "." or hiddenFilesAllowList[name] then
				local child = pathJoin(path, name)
				local stat = bundle:stat(child)
				if stat.type == "directory" then
					writer:add(child .. "/", "")
					copyFolder(child)
				elseif stat.type == "file" then
					print("    " .. child)
					writer:add(child, bundle:readfile(child), 9)
				end
			end
		end
	end
	print("Zipping " .. bundle.base)
	copyFolder("")
	print("Writing zip file")
	uv.fs_write(fd, writer:finalize(), binSize)
	uv.fs_close(fd)
	print("Done building " .. target)
	return
end

local PosixFileSystemMixin = require("PosixFileSystemMixin")
local ZipFileSystemMixin = require("ZipFileSystemMixin")

local function makeBundle(bundlePath)
	local path = pathJoin(uv.cwd(), bundlePath)
	local appBundle = {
		base = path,
		zipReader = miniz.new_reader(path) -- Can be nil for POSIX bundles, but that's working as intended
	}

	if appBundle.zipReader then
		mixin(appBundle, ZipFileSystemMixin)
		local topLevelDirectory = appBundle:getRootDirectory()
		if topLevelDirectory then
			appBundle:chroot(topLevelDirectory .. "/")
		end
		return appBundle
	end

	local stat = uv.fs_stat(path)
	if not stat then
		error(string.format("Failed to load %s (No such file exists)", path), 0)
	elseif stat.type ~= "directory" then
		error(string.format("Failed to load %s (Unsupported file type)", path), 0)
	end

	mixin(appBundle, PosixFileSystemMixin)

	return appBundle
end

local function commonBundle(bundlePath, mainPath, args)
	mainPath = mainPath or "main.lua"

	local bundle = assert(makeBundle(bundlePath))
	luvi.bundle = bundle

	bundle.paths = bundlePath
	bundle.mainPath = mainPath

	local function exportScriptGlobals()
		local cwd = uv.cwd()

		_G.DEFAULT_USER_SCRIPT_ENTRY_POINT = "main.lua"
		local scriptFile = args[1] or _G.DEFAULT_USER_SCRIPT_ENTRY_POINT

		local scriptPath = path.resolve(path.join(cwd, scriptFile))
		local scriptRoot = path.dirname(scriptPath)

		-- These will never change over the course of a single invocation, so it's safe to simply export them once
		_G.USER_SCRIPT_FILE = path.basename(scriptFile)
		_G.USER_SCRIPT_PATH = scriptPath
		_G.USER_SCRIPT_ROOT = scriptRoot
	end

	local main = bundle:readfile(mainPath)
	if not main then
		error("Entry point " .. mainPath .. " does not exist in app bundle " .. bundle.base, 0)
	end

	-- It's not helpful to display the app name if we're just executing a script on disk, and would likely be misleading
	-- But for zip apps, it's less confusing to see the executable name as the files referenced won't even exist on disk
	-- This is similar to how errors appear in NodeJS, with a node: prefix (which I like better than luvit's generic bundle: prefix)
	local executableName = path.basename(uv.exepath())
	local optionalPrefix = bundle.zipReader and (executableName .. ":" ) or ""
	-- @ option = render error message with <file name>:, not the generic ["string ..."] prefix, which is far less readable
	local fn = assert(loadstring(main, "@"  .. optionalPrefix .. mainPath))

	exportScriptGlobals()
	return fn(unpack(args))

end

-- Legacy export for makeBundle
luvi.makeBundle = makeBundle

return {
	buildBundle = buildBundle,
	makeBundle = makeBundle,
	commonBundle = commonBundle,
}
