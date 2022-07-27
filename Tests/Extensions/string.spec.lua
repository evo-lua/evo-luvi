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
end)
