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
			local chunk = "GET /awesome HTTP/1.1\r\n\r\n"

			print(type(parser.eventLogBuffer))
			print(parser.state.data)
			parser:ParseNextChunk(chunk)

			assertEquals(#parser.eventLogBuffer, #chunk)
			assertEquals(tostring(parser.eventLogBuffer), chunk)
		end)
	end)
end)