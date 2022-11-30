local IncrementalHttpParser = C_Networking.IncrementalHttpParser

describe("IncrementalHttpParser", function()
	describe("Construct", function()
		it("should initialize an empty event buffer", function()
			local parser = IncrementalHttpParser()
			local eventBuffer = parser:GetEventBuffer()

			assertEquals(parser:GetNumBufferedEvents(), 0)
			assertEquals(tostring(eventBuffer), "")
			assertEquals(#eventBuffer, 0)

			assertEquals(parser:GetBufferedEvents(), {})
		end)
	end)

	describe("ParseNextChunk", function()
		it("should populate the event buffer if at least one llhttp event is expected", function()
			local parser = IncrementalHttpParser()
			local chunk = "GET /awesome HTTP/1.1\r\n\r\n"

			parser:ParseNextChunk(chunk)

			print(parser:GetBufferedEvents())

			local eventBuffer = parser:GetEventBuffer()
			assertEquals(parser:GetNumBufferedEvents(), 42)
			assertEquals(tostring(eventBuffer), "test")
			assertEquals(#eventBuffer, 42)



			-- print(type(parser.eventBuffer))
			-- print(parser.state.data)

			-- assertEquals(#parser.eventBuffer, #chunk)
			-- assertEquals(tostring(parser.eventBuffer), chunk)
		end)
	end)
end)