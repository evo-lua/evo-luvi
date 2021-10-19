-- Primitives should be returned immediately from the require cache as they must be preloaded
print(package.preload["v8_string_helpers"])
print(package.preload["virtual_file_system"])
local v8_string_helpers = require("v8_string_helpers")
local virtual_file_system = require("virtual_file_system")

assertStrictEqual(type(v8_string_helpers), "table", "The V8 string helpers should be loaded")
assertStrictEqual(type(virtual_file_system), "table", "The virtual file system primitives should be loaded")