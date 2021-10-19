

print("This is the bundle's entry point")

local uv = require("uv")
local vfs = require("virtual_file_system")
-- TODO Move test to evo-luvi and use the existing assertion utilities
-- TODO Add CI workflow for this test

local import = _G.import

-- A module in the same folder can be loaded as-is
local bundledModule = import("bundled-module.lua")
assert(type(bundledModule) == "table", "Type of bundledModule is not table")
assert(bundledModule.someField == 42, "bundledModule.someField is not 42")

-- After a module has been loaded, it is cached and won't be reloaded from disk
bundledModule.isLoaded = true
assert(bundledModule.isLoaded == true, "bundledModule is loaded")
local reimportedModule, absolutePath, parentModule = import("bundled-module.lua")
assert(reimportedModule == bundledModule, "The re-imported module isn't retrieved from cache")
assert(reimportedModule.isLoaded == true, "reimportedModule is also loaded")

-- The path should be resolved directly from the entry point
local expectedAbsolutePath = path.join(_G.rootDirectory, "bundled-module.lua")
assert(absolutePath == expectedAbsolutePath, absolutePath .. " IS NOT " .. expectedAbsolutePath)

-- The parent should be the module that imported it, i.e. the main/entry point
assert(parentModule == path.join(_G.rootDirectory, "main.lua"), tostring(parentModule) .. " IS NOT " .. "main.lua")


-- The main module has no parent module (since it's not imported anywhere else, hopefully)

-- When a module is loaded from another file, its parent is set to the module that imported it

-- If no or invalid parameters are passed, we expect a nil return value and an error message (Lua style)
local returnValueShouldBeNil, errorMessage = import()
assert(returnValueShouldBeNil == nil, tostring(returnValueShouldBeNil) .. " IS NOT " .. type(nil))
assert(type(errorMessage) == "string", type(errorMessage) .. " IS NOT " .. "string")
assert(import() == import(""), "Empty strings should be treated the same as nil")
assert(import() == import("@"), "Empty epo package notation should be treated the same as nil")

-- Attempting to load a module without an extension should automatically append .lua (since native modules are loaded via FFI)
local bundledModuleLoadedWithoutExtension = import("bundled-module")
assert(bundledModule == bundledModuleLoadedWithoutExtension, ".lua extension was not appended automatically?")
assert(import("./bundled-module") == bundledModuleLoadedWithoutExtension, "Importing from cwd with dot prefix failed (without extension")
assert(import("./bundled-module.lua") == bundledModule, "Importing from cwd with dot prefix failed (with extension")

-- Import modules from file in local epo cache
-- No entry point given (modulePath is a folder): Use main.lua in that same folder
-- This requires special handling, because if .lua is blindly appended it can't work in this case
local epoModule = import("@test/example-package")
assert(type(epoModule) == "table", type(epoModule) .. " IS NOT table")
assert(epoModule.identifier == 123456789, tostring(epoModule.identifier) .. " IS NOT " .. 123456789)

assert(epoModule == import("@test/example-package/main.lua"), "Assumed entry point for epo package is not correct?")

-- Entry point given (modulePath is a file): Load that one instead
local epoModule2 = import("@foo/bar/nonstandard-entrypoint.lua")
assert(type(epoModule2) == "table", type(epoModule2) .. " IS NOT table")
assert(epoModule2.identifier == 987654321, tostring(epoModule2.identifier) .. " IS NOT " .. 987654321)

-- No owner/packageName given: Return nil and error message
local returnValueShouldBeNilAlso, anotherErrorMessage = import("@")
assert(returnValueShouldBeNilAlso == nil, tostring(returnValueShouldBeNilAlso) .. " IS NOT " .. type(nil))
assert(type(anotherErrorMessage) == "string", type(anotherErrorMessage) .. " IS NOT " .. "string")
