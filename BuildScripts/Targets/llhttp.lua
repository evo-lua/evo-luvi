local path_join = path.join

local StaticLibrary = import("../Ninja/StaticLibrary.lua")

local llhttp = StaticLibrary("llhttp")

local rootDirectory = path.join("..", "deps", "llhttp-ffi", "llhttp")
local includeDirectory = path.join(rootDirectory, "include")

local sources = {
	path_join("..", "deps", "llhttp-ffi", "llhttp", "CMakeLists.txt"),
}

llhttp:AddIncludeDirectory(includeDirectory)
llhttp:AddFiles(sources)

return llhttp