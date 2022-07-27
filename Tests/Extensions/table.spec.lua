describe("table", function()
	describe("count", function()
		it("should return zero for empty tables", function()
			assertEquals(table.count({}), 0)
		end)

		it("should return the number of array elements if the hash part is empty", function()
			assertEquals(table.count({ "Hello", "world", 42, 12345 }), 4)
		end)

		it("should return the number of hash map entries if the array part is empty", function()
			assertEquals(table.count({ Hello = 42, world = 123 }), 2)
		end)

		it("should return the total sum of hash map and array entries if neither part is empty", function()
			assertEquals(table.count({ "Hello world", Hello = 42 }), 2)
		end)

		it("should skip nils in the array part if the hash map part is empty", function()
			assertEquals(table.count({ 1, nil, 2, nil, 3 }), 3)
		end)

		it("should skip nils in the hash map part if the array part is empty", function()
			assertEquals(table.count({ hi = 42, nil, test = 43, nil, meep = 44 }), 3)
		end)

		it("should skip nils in tables that have both an array and a hash map part", function()
			assertEquals(table.count({ hi = 42, nil, 43, nil, meep = 44 }), 3)
		end)
	end)

	describe("diff", function()
		local diff = table.diff
		it("should raise an error if one of the two parameters is a non-table value", function()
			local expectedErrorMessage = "Usage: diff(before : table, after : table)"
			assertThrows(function()
				diff({}, 42)
			end, expectedErrorMessage)
			assertThrows(function()
				diff(function() end, {})
			end, expectedErrorMessage)
			assertThrows(function()
				diff("asdf", 42)
			end, expectedErrorMessage)
		end)

		it("should return an empty string if both tables are empty", function()
			assertEquals(diff({}, {}), "")
		end)

		it("should return an empty string if both tables are identical and non-empty", function()
			assertEquals(diff({ hi = 42, test = { nested = true } }, { hi = 42, test = { nested = true } }), "")
		end)

		it("should return a positive diff if the second table has a field that the first one is missing", function()
			local separatorLine = "--------------------"
			local expectedDiffString = separatorLine
				.. "\n"
				.. "{\n  hi = 42,\n  test = {\n    nested = true\n  }\n}"
				.. "\n"
				.. separatorLine
				.. "\n"
				.. "{\n  hi = 42,\n  test = {\n    nested = true,\n"
				.. string.rep(" ", 17)
				.. transform.brightRed("^ THERE BE A MISMATCH HERE")
				.. "\n    secret = 123\n  }\n}"
				.. "\n"
				.. separatorLine

			assertEquals(
				diff({ hi = 42, test = { nested = true } }, { hi = 42, test = { nested = true, secret = 123 } }),
				expectedDiffString
			)
		end)
	end)
end)
