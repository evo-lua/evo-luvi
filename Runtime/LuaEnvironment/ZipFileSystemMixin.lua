local ZipFileSystemMixin = {}

-- Can't use the builtin parth module because luvi's path resolved the zip VFS's root differently?
local luviPath = require("luvipath")
local path_join = luviPath.pathJoin

function ZipFileSystemMixin:stat(path)
	local zip = self.zipReader
	path = path_join("./" .. path)
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

function ZipFileSystemMixin:readdir(path)
	local zip = self.zipReader
	path = path_join("./" .. path)
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

function ZipFileSystemMixin:readfile(path)
	local zip = self.zipReader
	path = path_join("./" .. path)
	local index, err = zip:locate_file(path)
	if not index then
		return nil, err
	end
	return zip:extract(index)
end

return ZipFileSystemMixin