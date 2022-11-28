local IncrementalHttpParser = C_Networking.IncrementalHttpParser

describe("IncrementalHttpParser", function()
	describe("Construct", function()
		it("should initialize an empty event log buffer", function()
			local parser = IncrementalHttpParser()
			local eventLogBuffer = parser.eventLogBuffer

			assertEquals(parser.state.data, parser.eventLogBuffer:ref())

			assertEquals(tostring(eventLogBuffer), "")
			assertEquals(#eventLogBuffer, 0)
		end)
	end)

	describe("ParseNextChunk", function()
		it("should populate the event log queue if at least one llhttp event is expected", function()
			local parser = IncrementalHttpParser()
			parser:ParseNextChunk("test#123")

			assertEquals(#parser.eventLogBuffer, #"test#123")
			assertEquals(tostring(parser.eventLogBuffer), "test#123")
		end)
	end)
end)