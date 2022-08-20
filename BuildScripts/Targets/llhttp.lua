local StaticLibrary = import("../Ninja/StaticLibrary.lua")

local llhttp = StaticLibrary("llhttp")

local rootDirectory = path.join("deps", "llhttp-ffi", "llhttp")
local includeDirectory = path.join(rootDirectory, "include")

local sources = {
	"deps/llhttp-ffi/llhttp/src/api.c",
	"deps/llhttp-ffi/llhttp/src/http.c",
	"deps/llhttp-ffi/llhttp/src/llhttp.c",
}

llhttp:AddIncludeDirectory(includeDirectory)
llhttp:AddBuildTargets(sources)

return llhttp