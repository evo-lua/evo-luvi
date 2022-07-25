describe("assertThrows", function()
	it("should do nothing if the code under test raises the expected error", function()
		local function codeUnderTest()
			error("Some error message", 0)
		end
		local success = pcall(assertThrows, codeUnderTest, "Some error message")
		assertTrue(success)
	end)

	it("should fail if the code under test raises a different error", function()
		local function codeUnderTest()
			error("Not the same error message", 0)
		end
		local success = pcall(assertThrows, codeUnderTest, "Some error message")
		assertFalse(success)
	end)

	it("should fail if the code under test doesn't raise any error", function()
		local success = pcall(assertThrows, function() end, "Some error message")
		assertFalse(success)
	end)
end)
