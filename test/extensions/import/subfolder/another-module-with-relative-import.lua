local moduleWithParent = {
	someField = 666
}

local importedModule = import("../module-relative-import-target-subfolder.lua")
assert(importedModule.someField == 1337, "Importing with relative path from subfolder seems to have failed?")

return moduleWithParent