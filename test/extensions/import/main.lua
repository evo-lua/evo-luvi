
-- Upvalues
local uv = require("uv")
local vfs = require("virtual_file_system")
local type = type

-- Load assertion helpers into the global environment so that assertions are counted
import("assertions.lua") -- copy/paste job since there's no better way to add them currently

-- If import itself is broken this may fail, too, so let's make sure we notice right away
assertStrictEqual(type(assertStrictEqual), "function")

local import = _G.import
_G.currentNamespace = "import"

-- A module in the same folder can be loaded as-is
local bundledModule = import("bundled-module.lua")
assertStrictEqual(type(bundledModule), "table")
assertStrictEqual(bundledModule.someField, 42)

-- After a module has been loaded, it is cached and won't be reloaded from disk
bundledModule.isLoaded = true
assertStrictEqual(bundledModule.isLoaded, true, "Should be able to modify the state of loaded modules")
local reimportedModule, absolutePath, parentModule = import("bundled-module.lua")
assertStrictEqual(reimportedModule, bundledModule, "Should retrieve loaded modules from cache if present")
assertStrictEqual(reimportedModule.isLoaded, true, "Should persist the internal state of cached modules")

-- The path should be resolved directly from the entry point
local expectedAbsolutePath = path.join(_G.USER_SCRIPT_ROOT, "bundled-module.lua")
assertStrictEqual(absolutePath, expectedAbsolutePath)

-- The parent should be the module that imported it, i.e. the main/entry point
assertStrictEqual(parentModule, path.join(_G.USER_SCRIPT_ROOT, "main.lua"), "Should return the parent module after importing")

-- If no or invalid parameters are passed, we expect a nil return value and an error message (Lua style)
local returnValueShouldBeNil, errorMessage = import()
assertStrictEqual(returnValueShouldBeNil, nil, "Should return nil if no parameters were given")
assertStrictEqual(type(errorMessage), "string", "Should return an error message if no parameters were given")
assertStrictEqual(import(), import(""), "Should treat empty strings the same as nil")
assertStrictEqual(import(), import("@"), "@-notation: Evo package notation without parameters should be treated the same as nil")

-- Attempting to load a module without an extension should automatically append .lua (since native modules are loaded via FFI)
local bundledModuleLoadedWithoutExtension = import("bundled-module")
assertStrictEqual(bundledModule, bundledModuleLoadedWithoutExtension, "Should append the .lua extension if it was omitted")
assertStrictEqual(import("./bundled-module"), bundledModuleLoadedWithoutExtension, "Should load module from cwd with dot prefix (no extension")
assertStrictEqual(import("./bundled-module.lua"),  bundledModule, "Should load module from cwd with dot prefix (with extension")

-- Import modules from file in local evo cache
-- No entry point given (modulePath is a folder): Use main.lua in that same folder
-- This requires special handling, because if .lua is blindly appended it can't work in this case
local someModule = import("@test/example-package")
assertStrictEqual(type(someModule), "table", "@-notation: Should load successfully even if no entry point was given")
assertStrictEqual(someModule.identifier, 123456789, "@-notation: Should succeed loading module contents using the default entry point")
assertStrictEqual(someModule, import("@test/example-package/main.lua"), "@-notation: Should use main.lua as default entry point")

-- Entry point given (modulePath is a file): Load that one instead
local epoModule2 = import("@foo/bar/nonstandard-entrypoint.lua")
assertStrictEqual(type(epoModule2), "table")
assertStrictEqual(epoModule2.identifier, 987654321, "@-notation: Should load nonstandard entry point if one was given")

-- No owner/packageName given: Return nil and error message
local returnValueShouldBeNilAlso, anotherErrorMessage = import("@")
assertStrictEqual(returnValueShouldBeNilAlso, nil, "@-notation: Should return nil if no owner/package is given")
assertStrictEqual(type(anotherErrorMessage), "string", "@-notation: Should return an error message if no owner/package is given")
