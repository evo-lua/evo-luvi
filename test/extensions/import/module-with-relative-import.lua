local module = {
	someField = 777
}

local importedWithRelativePath = import("./module-relative-import-target.lua")
assert(importedWithRelativePath.someField == 567, "Relative import seems to have failed?")

return module