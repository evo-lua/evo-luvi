local print = print
local error = error
local format = string.format
local debug_traceback = debug.traceback

_G.numAssertions = 0

function _G.assertStrictEqual(actual, expected, label)
	label = label or _G.currentNamespace

	if actual ~= expected then
		print(format("FAIL\t%s\t%s IS NOT %s (%s)", label, actual, expected, _G.currentNamespace))
		error(format("\nExpected %s, actual: %s", expected, actual) .. "\n" .. debug_traceback())
	end
	print(format("PASS\t%s\t%s IS %s (%s)", label, actual, expected, _G.currentNamespace))

	numAssertions = numAssertions + 1
end
