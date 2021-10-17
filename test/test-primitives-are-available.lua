-- Primitives should be returned immediately from the require cache as they must be preloaded
print(package.preload["v8_string_helpers"])
local v8_string_helpers = require("v8_string_helpers")

assertStrictEqual(type(v8_string_helpers), "table", "The V8 string helpers should be loaded")