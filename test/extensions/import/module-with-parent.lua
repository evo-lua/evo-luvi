local moduleWithParent = {
	someField = 123,
}

local module = import("module-with-relative-import.lua")
assertStrictEqual(
	module.someField,
	777,
	"Should be able to load modules from cwd inside a module that isn't at the top-level in the parent hierarchy"
)
module = import("subfolder/another-module-with-relative-import.lua")
assertStrictEqual(
	module.someField,
	666,
	"Should be able to load modules from subfolder inside a module that isn't at the top-level in the parent hierarchy"
)

return moduleWithParent
