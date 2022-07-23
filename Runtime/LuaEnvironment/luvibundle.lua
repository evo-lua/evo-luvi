local uv = require("uv")
local miniz = require("miniz")
local luvi = require("luvi")
local luviPath = require("luvipath")
local pathJoin = luviPath.pathJoin
local getenv = require("os").getenv

local loadstring = loadstring or load
local unpack = unpack or _G.table.unpack

local tmpBase = luviPath.isWindows and (getenv("TMP") or uv.cwd()) or (getenv("TMPDIR") or "/tmp")

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

	function bundle:action(path, action, ...)
		-- If it's a real path, run it directly.
		if uv.fs_access(path, "r") then
			return action(path)
		end
		-- Otherwise, copy to a temporary folder and run from there
		local data, err = bundle.readfile(path)
		if not data then
			return nil, err
		end
		local dir = assert(uv.fs_mkdtemp(pathJoin(tmpBase, "lib-XXXXXX")))
		path = pathJoin(dir, path:match("[^/\\]+$"))
		local fd = uv.fs_open(path, "w", 384) -- 0600
		uv.fs_write(fd, data, 0)
		uv.fs_close(fd)
		local success, ret = pcall(action, path, ...)
		uv.fs_unlink(path)
		uv.fs_rmdir(dir)
		assert(success, ret)
		return ret
	end

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

	function bundle:register(name, path)
		if not path then
			path = name + ".lua"
		end
		package.preload[name] = function(...)
			local lua = assert(bundle.readfile(path))
			return assert(loadstring(lua, "bundle:" .. path))(...)
		end
	end

	local main = bundle:readfile(mainPath)
	if not main then
		error("Entry point " .. mainPath .. " does not exist in app bundle " .. bundle.base, 0)
	end
	local fn = assert(loadstring(main, "bundle:" .. mainPath))

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
