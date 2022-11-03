describe("utf8", function()
	local emoji = "🎃"

	describe("len", function()
		it("should return 1 when an emoji is passed", function()
			assertEquals(utf8.len(emoji), 1)
		end)
	end)

	describe("char", function()
		it("should return the concatenated unicode byte sequences if an emoji is passed", function()
			assertEquals(utf8.char(0x1F383), emoji)
		end)
	end)

	describe("match", function()
		it("should return the corresponding unicode character if a valid UTF8 byte sequence is passed", function()
			assertEquals(emoji:match(utf8.charpattern), emoji)
		end)
	end)

	describe("offset", function()
		it("should return 1 if a single valid unicode character is passed", function()
			assertEquals(utf8.offset(emoji, 1), 1)
		end)
	end)
end)
