local ModuleLoader = require("module_loader")


local assertStrictEqual = _G.assertStrictEqual

assertStrictEqual(ModuleLoader.EVO_PACKAGE_DIRECTORY, ".evo", "Should export evo package directory name as a constant")
-- Questionable
assertStrictEqual(#ModuleLoader.moduleCache, 0, "Should initialize an empty module cache")
assertStrictEqual(#ModuleLoader.prefixStack, 0, "Should initialize an empty prefix stack")

assertStrictEqual(type(ModuleLoader.ImportModule), "function", "Should export function ImportModule")
-- assertStrictEqual(type(ModuleLoader.GetScriptRoot), "function", "ModuleLoader.GetScriptRoot is a function")
-- assertStrictEqual(type(ModuleLoader.GetCurrentScript), "function", "ModuleLoader.GetCurrentScript is a function")
-- assertStrictEqual(type(ModuleLoader.GetModuleCache), "function", "ModuleLoader.GetModuleCache is a function")
-- assertStrictEqual(type(ModuleLoader.GetPrefixStack), "function", "ModuleLoader.GetPrefixStack is a function")