local uv = require("uv")
local miniz = require("miniz")
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

return {
	buildBundle = buildBundle,
}
