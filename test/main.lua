-- All paths should be relative to the project root so that Lua can find it
dofile("test/assertions.lua")

_G.currentNamespace = "primitives"
dofile("test/test-primitives-are-available.lua")
dofile("test/primitives/test-v8-string-lastindexof.lua")
dofile("test/primitives/test-vfs-interface-exists.lua")
dofile("test/primitives/test-module-loader-exists.lua")

_G.currentNamespace = "extensions"
dofile("test/test-extensions-are-loaded.lua")
dofile("test/extensions/test-path.lua")
dofile("test/extensions/test-dump.lua")

print(string.format("OK\tAll tests completed\t%d assertions", _G.numAssertions))