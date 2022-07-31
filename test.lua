local testCases = {
	"Runtime/LuaEnvironment/CLI.spec.lua",
	"Tests/Runtime/LuviAppBundle.spec.lua",
	"Tests/Runtime/API/EventSystem/EventListenerMixin.spec.lua",
	"Tests/Runtime/API/FileSystem/C_FileSystem.spec.lua",
	"Tests/Primitives/format.spec.lua",
	"Tests/Primitives/logging.spec.lua",
	"Tests/Primitives/printf.spec.lua",
	"Tests/Extensions/assertEquals.spec.lua",
	"Tests/Extensions/assertFunctionCalls.spec.lua",
	"Tests/Extensions/assertThrows.spec.lua",
	"Tests/Extensions/mixin.spec.lua",
	"Tests/Extensions/string.spec.lua",
	"Tests/Extensions/table.spec.lua",
	"Tests/Extensions/transform.spec.lua",
	-- The examples should run last as they may spam the console with irrelevant output
	"Tests/test-example-snippets.lua",
}

C_Testing.CreateUnitTestRunner(testCases)
