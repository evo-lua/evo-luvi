local ModuleLoader = require("module_loader")

local assertStrictEqual = _G.assertStrictEqual

-- Constants
assertStrictEqual(ModuleLoader.EVO_PACKAGE_DIRECTORY, ".evo", "Should export evo package directory name as a constant")
-- Questionable
assertStrictEqual(#ModuleLoader.moduleCache, 0, "Should initialize an empty module cache")
assertStrictEqual(#ModuleLoader.prefixStack, 0, "Should initialize an empty prefix stack")


-- ImportModule
assertStrictEqual(type(ModuleLoader.ImportModule), "function", "Should export function ImportModule")

local nonStringValues = {
	["number"] = 42,
	["table"] = {},
	["function"] = print,
	["nil"] = nil,
}
local expectedUsageError = "Usage: import(modulePath)"
for valueType, value in pairs(nonStringValues) do
	local loadedModule, errorMessage = ModuleLoader:ImportModule(value)
	assertStrictEqual(loadedModule, nil, "Should fail if the given module path is a " .. valueType)
	assertStrictEqual(errorMessage, expectedUsageError, "Should return an error if the given path is a " .. valueType)
end

local invalidStringValues = {
	"",
	"@",
}
for _, value in pairs(invalidStringValues) do
	local loadedModule, errorMessage = ModuleLoader:ImportModule(value)
	assertStrictEqual(loadedModule, nil, "Should fail if the given module path is " .. value)
	assertStrictEqual(errorMessage, expectedUsageError, "Should return an error if the given path is " .. value)
end


local loadedModule, errorMessage = ModuleLoader:ImportModule("@author/project")


-- assertStrictEqual(ModuleLoader:ImportModule(), "", "Should fail if the given module path is an empty string")


	-- assertStrictEqual(type(ModuleLoader.GetScriptRoot), "function", "ModuleLoader.GetScriptRoot is a function")
-- assertStrictEqual(type(ModuleLoader.GetCurrentScript), "function", "ModuleLoader.GetCurrentScript is a function")
-- assertStrictEqual(type(ModuleLoader.GetModuleCache), "function", "ModuleLoader.GetModuleCache is a function")
-- assertStrictEqual(type(ModuleLoader.GetPrefixStack), "function", "ModuleLoader.GetPrefixStack is a function")

error("meep")