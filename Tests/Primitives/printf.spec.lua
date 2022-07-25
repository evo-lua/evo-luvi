describe("printf", function()
	it("should be a globally exported alias", function()
		-- This can't easily be tested, so we want to at least make sure it's exported...
		assertEquals(type(_G.printf), "function")
	end)
end)
