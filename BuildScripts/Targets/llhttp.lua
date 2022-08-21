local path_join = path.join

local StaticLibrary = import("../Ninja/StaticLibrary.lua")

local llhttp = StaticLibrary("llhttp")

local rootDirectory = path.join("..", "deps", "llhttp-ffi", "llhttp")
local includeDirectory = path.join(rootDirectory, "include")

local sources = {
	path_join("..", "deps", "llhttp-ffi", "llhttp", "src", "api.c"),
	path_join("..", "deps", "llhttp-ffi", "llhttp", "src", "http.c"),
	path_join("..", "deps", "llhttp-ffi", "llhttp", "src", "llhttp.c"),
	-- path_join("..", "deps", "llhttp-ffi", "llhttp", "Makefile"),
}

llhttp:AddIncludeDirectory(includeDirectory)
llhttp:AddFiles(sources)

return llhttp