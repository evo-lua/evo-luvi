local bundledModule = {
	someField = 42
}

local uv = require("uv")

local moduleWithParent, absolutePath, parentModule = import("module-with-parent.lua")
assert(type(moduleWithParent) == "table", "moduleWithParent is not a table")
local expectedAbsolutePath = path.join(_G.rootDirectory, "module-with-parent.lua")
assert(absolutePath == expectedAbsolutePath, absolutePath .. " IS NOT " .. expectedAbsolutePath)
local selfPath = path.join(_G.rootDirectory, "bundled-module.lua")
assert(parentModule == selfPath, parentModule .. " IS NOT " .. selfPath)


return bundledModule