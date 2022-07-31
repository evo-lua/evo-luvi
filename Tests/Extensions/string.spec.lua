describe("string", function()
	describe("diff", function()
		it("should return nil if both strings are identical", function()
			assertEquals(string.diff("hello", "hello"), nil)
		end)

		it("should return the index of the first differing character if both strings are distinct", function()
			local index, lastNewlineIndex, numCharsSinceLastNewline = string.diff("Hello world", "Hello world!")
			assertEquals(index, 12)
			assertEquals(lastNewlineIndex, nil)
			assertEquals(numCharsSinceLastNewline, 11)
		end)

		it(
			"should return the index of the first differing character if both strings are distinct and contain multiple lines",
			function()
				local index, lastNewlineIndex, numCharsSinceLastNewline = string.diff("Hello\nworld!", "Hello\nworld!?")
				assertEquals(index, 13)
				assertEquals(lastNewlineIndex, 6)
				assertEquals(numCharsSinceLastNewline, 6)
			end
		)
	end)

	describe("explode", function()
		it("should return an array of whitespace-delimited tokens if no delimiter was passed ", function()
			assertEquals(string.explode("hello world"), { "hello", "world" })
		end)

		it("should return an array of tokens if the given delimiter occurs in the input string", function()
			assertEquals(string.explode("hello_world", "_"), { "hello", "world" })
		end)

		it("should return the input string itself if the given delimiter doesn't occur in it", function()
			assertEquals(string.explode("hello#world", "_"), { "hello#world" })
		end)

		it("should raise an error if no input string was given", function()
			local expectedError = "Usage: explode(inputString : string, delimiter : string?)"
			assertThrows(function()
				string.explode(nil)
			end, expectedError)
		end)
	end)
end)
