local v8_string = require("v8_string")
local vfs = require("virtual_file_system")

-- Primitives should be returned immediately from the require cache as they must be preloaded
assertStrictEqual(package.preload["v8_string"], v8_string, "Should preload the v8_string primitive")
assertStrictEqual(package.preload["virtual_file_system"], vfs, "Should preload the virtual_file_system primitive")

assertStrictEqual(type(v8_string), "table", "Should be able to require the v8_string primitive")
assertStrictEqual(type(vfs), "table", "Should be able to require the virtual_file_system primitive")