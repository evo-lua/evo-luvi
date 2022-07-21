local moduleWithParent = {
	someField = 666,
}

local importedModule = import("../module-relative-import-target-subfolder.lua")
assertStrictEqual(importedModule.someField, 1337, "Should be able to load modules with relative path from subfolder")

return moduleWithParent
