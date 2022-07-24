local uv = require("uv")
local miniz = require("miniz")
local luvi = require("luvi")
local luviPath = require("luvipath")
local pathJoin = luviPath.pathJoin

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

-- Legacy export for makeBundle
luvi.makeBundle = makeBundle

return {
	buildBundle = buildBundle,
	makeBundle = makeBundle,
}
