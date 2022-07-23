local uv = require("uv")
local miniz = require("miniz")
local luvi = require("luvi")
local luviPath = require("luvipath")
local pathJoin = luviPath.pathJoin
local getenv = require("os").getenv

local loadstring = loadstring or load
local unpack = unpack or _G.table.unpack

local tmpBase = luviPath.isWindows and (getenv("TMP") or uv.cwd()) or (getenv("TMPDIR") or "/tmp")

-- Bundle from folder on disk
local function folderBundle(base)
	local bundle = { base = base }

	function bundle.stat(path)
		path = pathJoin(base, "./" .. path)
		local raw, err = uv.fs_stat(path)
		if not raw then
			return nil, err
		end
		return {
			type = string.lower(raw.type),
			size = raw.size,
			mtime = raw.mtime,
		}
	end

	function bundle.readdir(path)
		path = pathJoin(base, "./" .. path)
		local req, err = uv.fs_scandir(path)
		if not req then
			return nil, err
		end

		local files = {}
		repeat
			local name = uv.fs_scandir_next(req)
			if name then
				files[#files + 1] = name
			end
		until not name
		return files
	end

	function bundle.readfile(path)
		path = pathJoin(base, "./" .. path)
		local fd, stat, data, err
		stat, err = uv.fs_stat(path)
		if not stat then
			return nil, err
		end
		if stat.type ~= "file" then
			return
		end
		fd, err = uv.fs_open(path, "r", 0644)
		if not fd then
			return nil, err
		end
		if stat then
			data, err = uv.fs_read(fd, stat.size, 0)
		end
		uv.fs_close(fd)
		return data, err
	end

	return bundle
end

-- Insert a prefix into all bundle calls
local function chrootBundle(bundle, prefix)
	local bundleStat = bundle.stat
	function bundle.stat(path)
		return bundleStat(prefix .. path)
	end
	local bundleReaddir = bundle.readdir
	function bundle.readdir(path)
		return bundleReaddir(prefix .. path)
	end
	local bundleReadfile = bundle.readfile
	function bundle.readfile(path)
		return bundleReadfile(prefix .. path)
	end
end

-- Use a zip file as a bundle
local function zipBundle(base, zip)
	local bundle = { base = base }

	function bundle.stat(path)
		path = pathJoin("./" .. path)
		if path == "" then
			return {
				type = "directory",
				size = 0,
				mtime = 0,
			}
		end
		local err
		local index = zip:locate_file(path)
		if not index then
			index, err = zip:locate_file(path .. "/")
			if not index then
				return nil, err
			end
		end
		local raw = zip:stat(index)

		return {
			type = raw.filename:sub(-1) == "/" and "directory" or "file",
			size = raw.uncomp_size,
			mtime = raw.time,
		}
	end

	function bundle.readdir(path)
		path = pathJoin("./" .. path)
		local index, err
		if path == "" then
			index = 0
		else
			path = path .. "/"
			index, err = zip:locate_file(path)
			if not index then
				return nil, err
			end
			if not zip:is_directory(index) then
				return nil, path .. " is not a directory"
			end
		end
		local files = {}
		for i = index + 1, zip:get_num_files() do
			local filename = zip:get_filename(i)
			if string.sub(filename, 1, #path) ~= path then
				break
			end
			filename = filename:sub(#path + 1)
			local n = string.find(filename, "/")
			if n == #filename then
				filename = string.sub(filename, 1, #filename - 1)
				n = nil
			end
			if not n then
				files[#files + 1] = filename
			end
		end
		return files
	end

	function bundle.readfile(path)
		path = pathJoin("./" .. path)
		local index, err = zip:locate_file(path)
		if not index then
			return nil, err
		end
		return zip:extract(index)
	end

	-- Support zips with a single folder inserted at top-level
	local entries = bundle.readdir("")
	if #entries == 1 and bundle.stat(entries[1]).type == "directory" then
		chrootBundle(bundle, entries[1] .. "/")
	end

	return bundle
end

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
		local files = bundle.readdir(path)
		if not files then
			return
		end
		for i = 1, #files do
			local name = files[i]
			if string.sub(name, 1, 1) ~= "." or hiddenFilesAllowList[name] then
				local child = pathJoin(path, name)
				local stat = bundle.stat(child)
				if stat.type == "directory" then
					writer:add(child .. "/", "")
					copyFolder(child)
				elseif stat.type == "file" then
					print("    " .. child)
					writer:add(child, bundle.readfile(child), 9)
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

local function makeBundle(bundlePath)
	local path = pathJoin(uv.cwd(), bundlePath)

	local zip = miniz.new_reader(path)
	if zip then
		return zipBundle(path, zip)
	end

	local stat = uv.fs_stat(path)
	if not stat then
		error(string.format("Failed to load %s (No such file exists)", path), 0)
	elseif stat.type ~= "directory" then
		error(string.format("Failed to load %s (Unsupported file type)", path), 0)
	end

	return folderBundle(path)
end

local function commonBundle(bundlePath, mainPath, args)
	mainPath = mainPath or "main.lua"

	local bundle = assert(makeBundle(bundlePath))
	luvi.bundle = bundle

	bundle.paths = bundlePath
	bundle.mainPath = mainPath

	function bundle.action(path, action, ...)
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

	function bundle.register(name, path)
		if not path then
			path = name + ".lua"
		end
		package.preload[name] = function(...)
			local lua = assert(bundle.readfile(path))
			return assert(loadstring(lua, "bundle:" .. path))(...)
		end
	end

	local main = bundle.readfile(mainPath)
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
	folderBundle = folderBundle,
	chrootBundle = chrootBundle,
	zipBundle = zipBundle,
	buildBundle = buildBundle,
	makeBundle = makeBundle,
	commonBundle = commonBundle,
}
