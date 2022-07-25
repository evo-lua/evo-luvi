describe("assertEquals", function()
	it("should do nothing if both inputs are equal", function()
		assertEquals(1, 1, "1 should be 1")
	end)

	it("should call the default ERROR handler on assertion failure", function()
		local originalErrorHandler = _G.ERROR

		local wasErrorHandlerCalled = false
		local lastErrorMessage = nil
		local function fauxErrorHandler(message)
			wasErrorHandlerCalled = true
			lastErrorMessage = message
		end

		_G.ERROR = fauxErrorHandler

		pcall(assertEquals, 1, 2, "1 should be 2") -- Need to avoid triggering errors here since we're intercepting them (awkward)
		assertTrue(wasErrorHandlerCalled, "Should call the default ERROR handler on assertion failure")

		-- There's a bit of an assertion-ception problem here, but that's merely an inconvenience
		local expectedText = transform.red("ASSERTION FAILURE: ")
			.. "Expected inputs to be equal ("
			.. transform.bold("1")
			.. " should be "
			.. transform.bold("2")
			.. ")"
			.. "\n"

		assertEquals(
			lastErrorMessage,
			expectedText,
			"Should pass an error message describing the assertion failure to the ERROR handler"
		)

		_G.ERROR = originalErrorHandler
	end)

	it("should do nothing if comparing two identical table values", function()
		local firstTable = {
			hello = "world",
			something = "else",
		}
		local secondTable = {
			hello = "world",
			something = "else",
		}
		assertEquals(firstTable, secondTable)
	end)

	it("should call the default ERROR handler when comparing two different table values", function()
		local firstTable = {
			hello = "world",
		}
		local secondTable = {
			something = "different",
		}

		local originalErrorHandler = _G.ERROR

		local wasErrorHandlerCalled = false
		local lastErrorMessage = nil
		local function fauxErrorHandler(message)
			wasErrorHandlerCalled = true
			lastErrorMessage = message
		end

		_G.ERROR = fauxErrorHandler

		-- Need to avoid triggering errors here since we're intercepting them (awkward)
		pcall(assertEquals, firstTable, secondTable, "Both tables should be identical")
		assertTrue(wasErrorHandlerCalled, "Should call the default ERROR handler on assertion failure")

		-- There's a bit of an assertion-ception problem here, but that's merely an inconvenience
		local expectedText = transform.red("ASSERTION FAILURE: ")
			.. "Expected inputs to be equal ("
			.. transform.bold("world")
			.. " should be "
			.. transform.bold("nil")
			.. ")"
			.. "\n"

		assertEquals(
			lastErrorMessage,
			expectedText,
			"Should pass an error message describing the assertion failure to the ERROR handler"
		)

		_G.ERROR = originalErrorHandler
	end)
end)
