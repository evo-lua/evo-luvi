local module = {
	someField = 777,
}

local importedWithRelativePath = import("./module-relative-import-target.lua")
assertStrictEqual(importedWithRelativePath.someField, 567, "Should be able to load modules using relative paths")

return module
