local testCases = {
	"Runtime/LuaEnvironment/CLI.spec.lua",
	"Tests/Runtime/LuviAppBundle.spec.lua",
	"Tests/Primitives/format.spec.lua",
	"Tests/Primitives/logging.spec.lua",
	"Tests/Extensions/assertEquals.spec.lua",
	"Tests/Extensions/assertFunctionCalls.spec.lua",
	"Tests/Extensions/assertThrows.spec.lua",
	"Tests/Extensions/mixin.spec.lua",
}

C_Testing.CreateUnitTestRunner(testCases)
