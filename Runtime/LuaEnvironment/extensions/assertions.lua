local tostring = tostring

local function assertDeepStrictEquals(actual, expected, description)
	if not (type(actual) == "table" and type(expected) == "table") then
		return assertEquals(actual, expected, description)
	end

	for k, v in pairs(actual) do
		if type(v) == "table" then
			assertDeepStrictEquals(v, expected[k])
		else
			assertEquals(v, expected[k])
		end
	end

	for k, v in pairs(expected) do
		if type(v) == "table" then
			assertDeepStrictEquals(v, actual[k])
		else
			assertEquals(v, actual[k])
		end
	end
end

function assertEquals(actual, expected, description)
	if actual == "" or tostring(actual) == "" then
		actual = "<empty string>"
	end
	if expected == "" or tostring(expected) == "" then
		expected = "<empty string>"
	end

	if type(actual) == "table" and type(expected) == "table" then
		return assertDeepStrictEquals(actual, expected, description)
	end

	if actual ~= expected then
		actual = tostring(actual)
		expected = tostring(expected)

		actual = transform.bold(actual)
		expected = transform.bold(expected)

		description = description or actual .. " is not " .. expected

		local errorMessage = transform.red("ASSERTION FAILURE: ")
			.. "Expected inputs to be equal"
			.. " "
			.. "("
			.. actual
			.. " should be "
			.. expected
			.. ")"
			.. "\n"
		ERROR(errorMessage)
	end
	assert(actual == expected, description)
end

function assertFalse(conditionToCheck, description)
	-- Taking the lazy way out here until requirements demand more sophistication
	assertEquals(conditionToCheck, false, description)
end

function assertTrue(conditionToCheck, description)
	-- Taking the lazy way out here until requirements demand more sophistication
	assertEquals(conditionToCheck, true, description)
end

function assertFunctionCalls(codeUnderTest, hostTable, targetFunctionName, numExpectedInvocations, description)
	description = description or "Should call function " .. targetFunctionName

	numExpectedInvocations = numExpectedInvocations or 1

	local backupFunctionToCall = hostTable[targetFunctionName]
	local numActualInvocations = 0

	local function spy(...)
		numActualInvocations = numActualInvocations + 1
		DEBUG("Spy called for function " .. targetFunctionName)
		backupFunctionToCall(...)
	end

	-- Must restore before asserting anything or unrelated tests may break
	hostTable[targetFunctionName] = spy
	codeUnderTest() -- Should call target function x times
	hostTable[targetFunctionName] = backupFunctionToCall

	assert(numActualInvocations == numExpectedInvocations, description)
end

function assertThrows(codeUnderTest, expectedErrorMessage)
	local success, errorMessage = pcall(codeUnderTest)
	assertFalse(success)
	assertEquals(errorMessage, expectedErrorMessage)
end

_G.assertEquals = assertEquals
_G.assertFalse = assertFalse
_G.assertTrue = assertTrue
_G.assertFunctionCalls = assertFunctionCalls
_G.assertThrows = assertThrows
