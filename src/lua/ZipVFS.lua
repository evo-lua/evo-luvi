local ZipVFS = {}

function ZipVFS:Construct(base, zip)
	local bundle = { base = base }

	function bundle.stat(path)
	  path = pathJoin("./" .. path)
	  if path == "" then
		return {
		  type = "directory",
		  size = 0,
		  mtime = 0
		}
	  end
	  local err
	  local index = zip:locate_file(path)
	  if not index then
		index, err = zip:locate_file(path .. "/")
		if not index then return nil, err end
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
		index, err = zip:locate_file(path )
		if not index then return nil, err end
		if not zip:is_directory(index) then
		  return nil, path .. " is not a directory"
		end
	  end
	  local files = {}
	  for i = index + 1, zip:get_num_files() do
		local filename = zip:get_filename(i)
		if string.sub(filename, 1, #path) ~= path then break end
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
	  if not index then return nil, err end
	  return zip:extract(index)
	end

	-- Support zips with a single folder inserted at top-level
	local entries = bundle.readdir("")
	if #entries == 1 and bundle.stat(entries[1]).type == "directory" then
	  chrootBundle(bundle, entries[1] .. '/')
	end

	return bundle
end

-- folderBundle
function bundle.stat(path)
    path = pathJoin(base, "./" .. path)
    local raw, err = uv.fs_stat(path)
    if not raw then return nil, err end
    return {
      type = string.lower(raw.type),
      size = raw.size,
      mtime = raw.mtime,
    }
  end

-- chrootBundle
local bundleStat = bundle.stat
function bundle.stat(path)
  return bundleStat(prefix .. path)
end

-- zipBundle
function bundle.stat(path)
    path = pathJoin("./" .. path)
    if path == "" then
      return {
        type = "directory",
        size = 0,
        mtime = 0
      }
    end
    local err
    local index = zip:locate_file(path)
    if not index then
      index, err = zip:locate_file(path .. "/")
      if not index then return nil, err end
    end
    local raw = zip:stat(index)

    return {
      type = raw.filename:sub(-1) == "/" and "directory" or "file",
      size = raw.uncomp_size,
      mtime = raw.time,
    }
  end

  -- combinedBundle
  function bundle.stat(path)
    local err
    for i = 1, #bundles do
      local stat
      stat, err = bundles[i].stat(path)
      if stat then return stat end
    end
    return nil, err
  end

return ZipVFS