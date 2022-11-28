local IncrementalHttpParser = C_Networking.IncrementalHttpParser

describe("IncrementalHttpParser", function()
	describe("Construct", function()
		it("should initialize an empty event log buffer", function()
			local parser = IncrementalHttpParser()
			local eventLogBuffer = parser.eventLogBuffer

			dump(parser)

			assertEquals(parser.state.data, parser.eventLogBuffer:ref())

			assertEquals(tostring(eventLogBuffer), "")
			assertEquals(#eventLogBuffer, 0)
		end)
	end)
end)