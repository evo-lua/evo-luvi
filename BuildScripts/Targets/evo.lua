
local evo = Executable("evo")

evo:AddIncludeDirectory(path_join("Runtime"))

local sources = {
	path_join("Runtime", "main.c"),
	path_join("Runtime", "luvi_compat.c"),

-- Runtime/LuaEnvironment/CLI.lua
-- Runtime/LuaEnvironment/init.lua
-- Runtime/LuaEnvironment/luvipath.lua
-- Runtime/LuaEnvironment/LuviAppBundle.lua
-- Runtime/LuaEnvironment/PosixFileSystemMixin.lua
-- Runtime/LuaEnvironment/ZipFileSystemMixin.lua
-- Runtime/LuaEnvironment/primitives.lua
-- Runtime/LuaEnvironment/primitives/aliases.lua
-- Runtime/LuaEnvironment/primitives/dump.lua
-- Runtime/LuaEnvironment/primitives/v8_string.lua
-- Runtime/LuaEnvironment/primitives/logging.lua
-- Runtime/LuaEnvironment/primitives/virtual_file_system.lua
-- Runtime/LuaEnvironment/extensions.lua
-- Runtime/LuaEnvironment/extensions/assertions.lua
-- Runtime/LuaEnvironment/extensions/import.lua
-- Runtime/LuaEnvironment/extensions/libuvx.lua
-- Runtime/LuaEnvironment/extensions/mixin.lua
-- Runtime/LuaEnvironment/extensions/path.lua
-- Runtime/LuaEnvironment/extensions/stringx.lua
-- Runtime/LuaEnvironment/extensions/tablex.lua
-- Runtime/LuaEnvironment/extensions/transform.lua
-- Runtime/LuaEnvironment/namespaces.lua
-- Runtime/API/EventSystem/EventListenerMixin.lua
-- Runtime/API/EventSystem/C_EventSystem.lua
-- Runtime/Primitives/AsyncHandleMixin.lua
-- Runtime/Primitives/AsyncStreamMixin.lua
-- Runtime/Primitives/AsyncSocketMixin.lua
-- Runtime/API/FileSystem/C_FileSystem.lua
-- Runtime/API/Testing/Scenario.lua
-- Runtime/API/Testing/TestSuite.lua
-- Runtime/API/Networking/TcpSocket.lua
-- Runtime/API/Networking/TcpClient.lua
-- Runtime/API/Networking/TcpServer.lua
-- Runtime/API/Networking/C_Networking.lua
-- Runtime/API/Testing/C_Testing.lua
-- ${lpeg_re_lua}
-- ${LLHTTP_FFI_SOURCE_DIRECTORY}/llhttp.lua
}
evo:AddBuildTargets(sources)
evo:AddDependency(llhttp)
-- evo:AddDependency(luajit)
-- evo:AddDependency()
-- evo:AddDependency(libuv)
-- local llhttp = StaticLibrary("ssl")
-- local llhttp = StaticLibrary("crypto")
-- local llhttp = StaticLibrary("luv")
-- local llhttp = StaticLibrary("libuv")