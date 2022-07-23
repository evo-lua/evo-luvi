local PosixFileSystemMixin = {}

local path_join = require("path").join
local uv = require("uv")

-- Bundle from folder on disk
function PosixFileSystemMixin:stat(path)
	local base = self.base
	path = path_join(base, "./" .. path)
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

function PosixFileSystemMixin:readdir(path)
	local base = self.base

	path = path_join(base, "./" .. path)
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

function PosixFileSystemMixin:readfile(path)
	local base = self.base
	path = path_join(base, "./" .. path)
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

return PosixFileSystemMixin