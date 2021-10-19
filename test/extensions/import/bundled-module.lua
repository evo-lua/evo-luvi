local bundledModule = {
	someField = 42
}

local uv = require("uv")

local moduleWithParent, absolutePath, parentModule = import("module-with-parent.lua")
assertStrictEqual(type(moduleWithParent), "table", "Should return the exports of loaded modules")
local expectedAbsolutePath = path.join(_G.rootDirectory, "module-with-parent.lua")
assertStrictEqual(absolutePath, expectedAbsolutePath, "Should return the absolute path of loaded modules")
local selfPath = path.join(_G.rootDirectory, "bundled-module.lua")
assertStrictEqual(parentModule, selfPath, "Should return the parent module of loaded modules")

return bundledModule