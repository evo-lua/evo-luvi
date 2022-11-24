local ffi = require("ffi")

local isWindows = (ffi.os == "Windows")

local C_BuildTools = {
	OBJECT_FILE_EXTENSION = (isWindows and "obj" or "o"),
	STATIC_LIBRARY_EXTENSION = (isWindows and ".lib" or ".a"),
	SHARED_LIBRARY_EXTENSION = (isWindows and ".dll" or ".so"),
	EXECUTABLE_FILE_EXTENSION = (isWindows and ".exe" or ""),
	DEFAULT_BUILD_DIRECTORY_NAME = "ninjabuild-" .. (isWindows and "windows" or "unix"),
	GCC_COMPILATION_SETTINGS = {
		displayName = "GNU Compiler Collection",
		C_COMPILER = "gcc", -- I guess it could be cc on some systems, but let's ignore that for now....
		COMPILER_FLAGS = "-O2 -DNDEBUG -g -Wall -Wextra -Wno-missing-field-initializers -Wno-unused-parameter -fvisibility=hidden -fno-strict-aliasing",
		C_LINKER = "gcc",
		-- Must export the entry point of bytecode objects so that LuaJIT can load them via require()
		LINKER_FLAGS = isWindows and "-Wl,--export-all-symbols" or "-rdynamic",
		C_ARCHIVER = "ar",
		ARCHIVER_FLAGS = "-rcs",
	},
}

function C_BuildTools.GetStaticLibraryName(libraryBaseName)
	return (isWindows and "" or "lib") .. libraryBaseName .. C_BuildTools.STATIC_LIBRARY_EXTENSION
end

function C_BuildTools.GetSharedLibraryName(libraryBaseName)
	return (isWindows and "" or "lib") .. libraryBaseName .. C_BuildTools.SHARED_LIBRARY_EXTENSION
end

function C_BuildTools.GetExecutableName(libraryBaseName)
	return libraryBaseName .. C_BuildTools.EXECUTABLE_FILE_EXTENSION
end

function C_BuildTools.DiscoverGitVersionTag()
	local gitDescribeCommand = "git describe --tags"

	local file = assert(io.popen(gitDescribeCommand, "r"))
	file:flush() -- Required to prevent receiving only partial output
	local output = file:read("*all")
	file:close()

	-- Strip final newline since that's not very useful outside of the shell
	output = string.sub(output, 0, string.len(output) - 1)
	return output
end

return C_BuildTools
