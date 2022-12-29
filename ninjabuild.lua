-- CAUTION: This script (and all of its dependencies) MUST run as-is in stock LuaJIT, so that the runtime can be bootstrapped from source
-- That means you can only use standard LuaJIT functionality here, or the few dedicated modules designed to be portable (BuildTools API)
local ffi = require("ffi")
local isWindows = (ffi.os == "Windows")

local C_BuildTools = require("Runtime.API.BuildTools.C_BuildTools")
local NinjaFile = require("Runtime.API.BuildTools.NinjaFile")

local format = string.format
local GetExecutableName = C_BuildTools.GetExecutableName

local EvoBuildTarget = {
	OUTPUT_FILE_NAME = GetExecutableName("evo"),
	BUILD_DIR = C_BuildTools.DEFAULT_BUILD_DIRECTORY_NAME,
	GIT_VERSION_TAG = C_BuildTools.DiscoverGitVersionTag(),
	-- Can't easily discover sources or resolve paths with only LuaJIT/Lua APIs, but listing them explicitly is probably safer anyway
	-- Note that ninja doesn't care about path separators and the mingw toolchain supports forward slashes,  ignore \ on Windows
	luaSources = {
		"Runtime/LuaEnvironment/CLI.lua",
		"Runtime/LuaEnvironment/init.lua",
		"Runtime/LuaEnvironment/luvipath.lua",
		"Runtime/LuaEnvironment/LuviAppBundle.lua",
		"Runtime/LuaEnvironment/PosixFileSystemMixin.lua",
		"Runtime/LuaEnvironment/ZipFileSystemMixin.lua",
		"Runtime/LuaEnvironment/primitives.lua",
		"Runtime/LuaEnvironment/primitives/aliases.lua",
		"Runtime/LuaEnvironment/primitives/dump.lua",
		"Runtime/LuaEnvironment/primitives/extend.lua",
		"Runtime/LuaEnvironment/primitives/v8_string.lua",
		"Runtime/LuaEnvironment/primitives/logging.lua",
		"Runtime/LuaEnvironment/primitives/virtual_file_system.lua",
		"Runtime/LuaEnvironment/extensions.lua",
		"Runtime/LuaEnvironment/extensions/assertions.lua",
		"Runtime/LuaEnvironment/extensions/import.lua",
		"Runtime/LuaEnvironment/extensions/libuvx.lua",
		"Runtime/LuaEnvironment/extensions/mixin.lua",
		"Runtime/LuaEnvironment/extensions/path.lua",
		"Runtime/LuaEnvironment/extensions/stringx.lua",
		"Runtime/LuaEnvironment/extensions/tablex.lua",
		"Runtime/LuaEnvironment/extensions/transform.lua",
		"Runtime/LuaEnvironment/extensions/url.lua",
		"Runtime/LuaEnvironment/namespaces.lua",
		"Runtime/API/EventSystem/EventListenerMixin.lua",
		"Runtime/API/EventSystem/C_EventSystem.lua",
		"Runtime/Primitives/AsyncHandleMixin.lua",
		"Runtime/Primitives/AsyncStreamMixin.lua",
		"Runtime/Primitives/AsyncSocketMixin.lua",
		"Runtime/API/BuildTools/NinjaFile.lua",
		"Runtime/API/BuildTools/C_BuildTools.lua",
		"Runtime/API/FileSystem/C_FileSystem.lua",
		"Runtime/API/Testing/Scenario.lua",
		"Runtime/API/Testing/TestSuite.lua",
		"Runtime/API/Networking/IncrementalHttpParser.lua",
		"Runtime/API/Networking/TcpSocket.lua",
		"Runtime/API/Networking/TcpClient.lua",
		"Runtime/API/Networking/TcpServer.lua",
		"Runtime/API/Networking/C_Networking.lua",
		"Runtime/API/Testing/C_Testing.lua",
		"deps/lpeg/re.lua",
		"deps/llhttp.lua",
	},
	cSources = {
		"Runtime/main.c",
		"Runtime/runtime.c",
		"Runtime/luvi_compat.c",
		"Runtime/Bindings/llhttp_ffi.c",
		-- Some of the deps don't have a real build system. Since they're tiny (mostly glue code), just incorporate them here (for now)
		"deps/lua-zlib/lua_zlib.c",
		-- LPEG doesn't have a build system that would work on Windows, so homebrew it is...
		"deps/lpeg/lpvm.c",
		"deps/lpeg/lptree.c",
		"deps/lpeg/lpprint.c",
		"deps/lpeg/lpcode.c",
		"deps/lpeg/lpcap.c",
		-- lrexlib only supports luarocks builds, which are a disaster on Windows... I'd rather not go there again, ever.
		"deps/lrexlib/src/common.c",
		"deps/lrexlib/src/pcre2/lpcre2.c",
		"deps/lrexlib/src/pcre2/lpcre2_f.c",
	},
	includeDirectories = {
		C_BuildTools.DEFAULT_BUILD_DIRECTORY_NAME, -- For auto-generated headers (PCRE2)
		"deps/luv/src",
		"deps/luv/deps/libuv/include",
		"deps/luv/deps/luajit/src",
		"deps/luv/deps/lua-compat-5.3",
		"deps/luv/deps/lua-compat-5.3/c-api",
		"deps/llhttp/include",
		"deps/lua-openssl/src",
		"deps/lua-openssl/deps/auxiliar",
		"deps/openssl/include",
		"deps/pcre2/src",
		"deps/zlib",
	},
	staticLibraries = {
		-- Assuming Unix naming conventions here since that's what most of the libraries use
		"libluajit.a",
		"libluv.a",
		"libuv_a.a",
		"libllhttp.a",
		"openssl.a",
		"libssl.a",
		"libcrypto.a",
		"libpcre2-8.a",
		"zlibstatic.a",
	},
	-- All those Windows system libraries are due to libuv and openssl, can't really remove them :(
	sharedLibraries = (
		isWindows and "-l PSAPI -l USER32 -l ADVAPI32 -l IPHLPAPI -l USERENV -l WS2_32 -l GDI32 -l CRYPT32"
		or "-lm -ldl -pthread"
	),
}

function EvoBuildTarget:GenerateNinjaFile()
	self.ninjaFile = NinjaFile()
	self.objectFiles = {}

	local GCC = C_BuildTools.GCC_COMPILATION_SETTINGS
	self:SetCompilerToolchain(GCC)
	self:SetLuaBytecodeGenerator()

	self:ComputeBuildEdges()

	return self.ninjaFile
end

function EvoBuildTarget:SetCompilerToolchain(toolchainInfo)
	local ninjaFile = self.ninjaFile

	ninjaFile:AddVariable("C_COMPILER", toolchainInfo.C_COMPILER)
	ninjaFile:AddVariable("COMPILER_FLAGS", toolchainInfo.COMPILER_FLAGS)
	ninjaFile:AddVariable("C_LINKER", toolchainInfo.C_LINKER)
	ninjaFile:AddVariable("LINKER_FLAGS", toolchainInfo.LINKER_FLAGS)
	ninjaFile:AddVariable("C_ARCHIVER", toolchainInfo.C_ARCHIVER)
	ninjaFile:AddVariable("ARCHIVER_FLAGS", toolchainInfo.ARCHIVER_FLAGS)

	-- Technically, this is still specific to GCC due to the emitted deps file, but that could easily be changed later (if needed)
	ninjaFile:AddRule(
		"compile",
		"$C_COMPILER -c $in -o $out -MT $out -MMD -MF $out.d $COMPILER_FLAGS $includes $defines",
		{
			description = "Compiling $in ...",
			deps = "$C_COMPILER",
			depfile = "$out.d",
		}
	)
	ninjaFile:AddRule("link", "$C_LINKER $in -o $out $libs $LINKER_FLAGS", { description = "Linking target $out ..." })

	self.toolchain = toolchainInfo
end

function EvoBuildTarget:SetLuaBytecodeGenerator()
	-- Only LuaJIT is (and likely ever will be) supported
	local ninjaFile = self.ninjaFile

	local LUAJIT_EXECUTABLE_PATH = self.BUILD_DIR .. "/" .. GetExecutableName("luajit")
	ninjaFile:AddVariable("LUAJIT_EXECUTABLE", LUAJIT_EXECUTABLE_PATH)

	ninjaFile:AddRule(
		"bcsave",
		"$LUAJIT_EXECUTABLE -bg $in $out",
		{ description = "Saving LuaJIT bytecode for $in ..." }
	)

	self.bytecodeGenerator = LUAJIT_EXECUTABLE_PATH
end

function EvoBuildTarget:ComputeBuildEdges()
	self:ProcessNativeSources()
	self:ProcessLuaSources()
	self:ProcessStaticLibraries()
end

function EvoBuildTarget:ProcessNativeSources()
	local ninjaFile = self.ninjaFile
	local objectFiles = self.objectFiles

	-- No point in fine-tuning include dirs since there's no duplicate headers anywhere, so just pass all of them every time
	local includes = ""
	for _, includeDir in ipairs(self.includeDirectories) do
		includes = includes .. "-I " .. includeDir .. " "
	end

	for index, cSourceFilePath in ipairs(self.cSources) do
		local outputFile = format("%s/%s.%s", self.BUILD_DIR, cSourceFilePath, C_BuildTools.OBJECT_FILE_EXTENSION)

		-- Some dependencies demand special treatment because of how they use defines (questionably?)
		local defines = self:GetDefines(cSourceFilePath)
		ninjaFile:AddBuildEdge(outputFile, "compile " .. cSourceFilePath, { includes = includes, defines = defines })

		table.insert(objectFiles, outputFile)
	end
end

function EvoBuildTarget:GetDefines(cSourceFilePath)
	local defines = format('-DEVO_VERSION=\\"%s\\"', self.GIT_VERSION_TAG)

	local pcreDefines = "-DPCRE2_STATIC -DPCRE2_CODE_UNIT_WIDTH=8"
	defines = defines .. " " .. pcreDefines -- Since the runtime itself uses PCRE2 APIs to export the version, this is mandatory

	-- LREXLIB requires a VERSION define, which would be set by luarocks if we used that... but we don't, so discover it manually (hacky!)
	if string.match(cSourceFilePath, "lrexlib") then
		local lrexlibVersionString = self.discoveredLrexlibVersion or self:DiscoverLrexlibVersion()
		self.discoveredLrexlibVersion = lrexlibVersionString -- Only do it once, not once per file...

		-- LREXLIB's overly generic VERSION define causes a conflict with LPEG (which does the same thing)
		defines = defines .. format(' -DVERSION=\\"%s\\"', lrexlibVersionString)
	end

	return defines
end

function EvoBuildTarget:DiscoverLrexlibVersion()
	-- This is somewhat sketchy as it relies on many assumptions, but since lrexlib isn't really maintained that's probably OK-ish...
	-- The version is hardcoded in their Makefile and then propagated to the luarocks configuration
	local lrexlibMakefile = io.open("deps/lrexlib/Makefile", "r") -- Unix paths should be fine on MSYS
	local makefileContents = lrexlibMakefile:read("*a") -- It's not big, so no problem to keep it in memory here

	local expectedVersionPattern = "VERSION = (%d+.%d+.%d+)" -- Hopefully they will never change it :/
	local discoveredLrexlibVersion = string.match(makefileContents, expectedVersionPattern)

	lrexlibMakefile:close()

	return discoveredLrexlibVersion
end

function EvoBuildTarget:ProcessLuaSources()
	local ninjaFile = self.ninjaFile
	local objectFiles = self.objectFiles

	for index, luaSourceFilePath in ipairs(self.luaSources) do
		local outputFile = format("%s/%s.%s", self.BUILD_DIR, luaSourceFilePath, C_BuildTools.OBJECT_FILE_EXTENSION)
		ninjaFile:AddBuildEdge(outputFile, "bcsave " .. luaSourceFilePath)
		table.insert(objectFiles, outputFile)
	end
end

function EvoBuildTarget:ProcessStaticLibraries()
	local ninjaFile = self.ninjaFile
	local objectFiles = self.objectFiles

	-- Static libraries are linked in just like any other object, but at the very end (so that their symbols are resolved correctly)
	for index, libraryBaseName in ipairs(self.staticLibraries) do
		local relativeLibraryPath = self.BUILD_DIR .. "/" .. libraryBaseName
		table.insert(objectFiles, relativeLibraryPath)
	end

	ninjaFile:AddBuildEdge(
		self.BUILD_DIR .. "/" .. self.OUTPUT_FILE_NAME,
		"link " .. table.concat(objectFiles, " "),
		{ libs = self.sharedLibraries }
	)
end

function EvoBuildTarget:ToString()
	return format(
		[[

Target: %s
Version: %s
Build Directory: %s
Compiler Toolchain: %s
Bytecode Generator: %s
]],
		self.OUTPUT_FILE_NAME,
		self.GIT_VERSION_TAG,
		self.BUILD_DIR,
		self.toolchain.displayName,
		self.bytecodeGenerator
	)
end

print("Generating build configuration ...")
local ninjaFile = EvoBuildTarget:GenerateNinjaFile()

print(EvoBuildTarget:ToString())

print("Saving Ninja file: " .. NinjaFile.DEFAULT_BUILD_FILE_NAME)
ninjaFile:Save()
