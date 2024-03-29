local testCases = {
	"Tests/Runtime/runtime.spec.lua",
	"Tests/Runtime/CLI.spec.lua",
	"Tests/Runtime/LuviAppBundle.spec.lua",
	"Tests/Runtime/API/BuildTools/NinjaFile.spec.lua",
	"Tests/Runtime/API/BuildTools/C_BuildTools.spec.lua",
	"Tests/Runtime/API/EventSystem/EventListenerMixin.spec.lua",
	"Tests/Runtime/API/EventSystem/C_EventSystem.spec.lua",
	"Tests/Runtime/API/FileSystem/C_FileSystem.spec.lua",
	"Tests/Runtime/API/Testing/Scenario.spec.lua",
	"Tests/Runtime/API/Testing/TestSuite.spec.lua",
	"Tests/Runtime/API/Networking/IncrementalHttpParser.spec.lua",
	"Tests/Runtime/API/Networking/C_Networking.spec.lua",
	"Tests/Primitives/extend.spec.lua",
	"Tests/Primitives/format.spec.lua",
	"Tests/Primitives/logging.spec.lua",
	"Tests/Primitives/printf.spec.lua",
	"Tests/Extensions/assertEquals.spec.lua",
	"Tests/Extensions/assertFunctionCalls.spec.lua",
	"Tests/Extensions/assertThrows.spec.lua",
	"Tests/Extensions/llhttp.spec.lua",
	"Tests/Extensions/lpeg.spec.lua",
	"Tests/Extensions/miniz.spec.lua",
	"Tests/Extensions/mixin.spec.lua",
	"Tests/Extensions/openssl.spec.lua",
	"Tests/Extensions/regex.spec.lua",
	"Tests/Extensions/string.spec.lua",
	"Tests/Extensions/table.spec.lua",
	"Tests/Extensions/transform.spec.lua",
	"Tests/Extensions/utf8.spec.lua",
	"Tests/Extensions/uv.spec.lua",
	"Tests/Extensions/zlib.spec.lua",
}

C_Testing.CreateUnitTestRunner(testCases)
