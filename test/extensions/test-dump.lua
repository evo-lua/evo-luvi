local path = _G.dump
_G.currentNamespace = "dump"

-- I would hope all this (and more) is already covered by inspect.lua, but it's better to be safe
local someTable = { test = 42 }
local someFunction = function()
	print("It doesn't matter what we do in here")
end
local testCases = {
	-- Format: input; expectedOutput
	["Table serialization"] = { input = someTable, expectedOutput = "{\n\ttest = 42\n}" },
	["Boolean value: true"] = { input = true, expectedOutput = "true" },
	["Boolean value: false"] = { input = false, expectedOutput = "false" },
	["Boolean value: nil"] = { input = nil, expectedOutput = "nil" },
	["String values are escaped with double-quotes"] = { input = "Hello", expectedOutput = '"Hello"' },
	["Function values are converted to strings"] = { input = someFunction, expectedOutput = "<function 1>" },
}

for label, testCase in pairs(testCases) do
	assertStrictEqual(dump(testCase.input), testCase.expectedOutput, label)
end
