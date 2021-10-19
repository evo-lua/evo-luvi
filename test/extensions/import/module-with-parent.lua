local moduleWithParent = {
	someField = 123
}

local module = import("module-with-relative-import.lua")
local module = import("subfolder/another-module-with-relative-import.lua")

return moduleWithParent