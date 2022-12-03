local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")
local ffi = require("ffi")

local websocketsRequestString =
    "GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"

describe("IncrementalHttpParser", function()
    describe("Construct", function()
        local parser = IncrementalHttpParser()
        it("should initialize the parser with an empty event buffer", function()
            assertEquals(parser:GetNumBufferedEvents(), 0)
            assertEquals(parser:GetEventBufferSize(), 0)
            assertEquals(parser:GetBufferedEvents(), {})
        end)

        it("should register handlers for all llhttp-ffi events", function()
            local expectedEventHandlers = llhttp.FFI_EVENTS

            for _, eventID in ipairs(expectedEventHandlers) do
                assertEquals(type(parser[eventID]), "function",
                             "Should register listener for event " .. eventID)
            end

            assertEquals(type(parser["HTTP_EVENT_BUFFER_TOO_SMALL"]),
                         "function", "Should register listener for event " ..
                             "HTTP_EVENT_BUFFER_TOO_SMALL")
        end)
    end)

    describe("ParseNextChunk", function()
        it(
            "should not modify the event buffer if the parser didn't trigger any events",
            function()
                local parser = IncrementalHttpParser()
                local numEventsBefore = parser:GetNumBufferedEvents()
                local bufferSizeBefore = parser:GetEventBufferSize()
                local eventListBefore = parser:GetBufferedEvents()

                parser:ParseNextChunk("") -- Parsing literally any other string WILL trigger an event, if only MESSAGE_BEGIN ...

                local numEventsAfter = parser:GetNumBufferedEvents()
                local bufferSizeAfter = parser:GetEventBufferSize()
                local eventListAfter = parser:GetBufferedEvents()

                assertEquals(numEventsBefore, numEventsAfter)
                assertEquals(bufferSizeBefore, bufferSizeAfter)
                assertEquals(eventListBefore, eventListAfter)
            end)

        it(
            "should add all events to the buffer if any were triggered and the buffer is empty",
            function()
                local parser = IncrementalHttpParser()

                parser:ParseNextChunk(websocketsRequestString)

                local numEventsAfter = parser:GetNumBufferedEvents()
                local bufferSizeAfter = parser:GetEventBufferSize()
                local eventListAfter = parser:GetBufferedEvents()

                -- Don't care whether the cdata point to the same memory, just that the event details are identical...
                local expectedEventList = {
                    {eventID = "HTTP_ON_MESSAGE_BEGIN", payload = ""},
                    {eventID = "HTTP_ON_METHOD", payload = "GET"},
                    {eventID = "HTTP_ON_METHOD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_URL", payload = "/chat"},
                    {eventID = "HTTP_ON_URL_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_VERSION", payload = "1.1"},
                    {eventID = "HTTP_ON_VERSION_COMPLETE", payload = ""},
                    {eventID = "HTTP_HEADER_FIELD", payload = "Host"},
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_ON_HEADER_VALUE",
                        payload = "example.com:8000"
                    },
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {eventID = "HTTP_HEADER_FIELD", payload = "Upgrade"},
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADER_VALUE", payload = "websocket"},
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {eventID = "HTTP_HEADER_FIELD", payload = "Connection"},
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADER_VALUE", payload = "Upgrade"},
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_HEADER_FIELD",
                        payload = "Sec-WebSocket-Key"
                    },
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_ON_HEADER_VALUE",
                        payload = "dGhlIHNhbXBsZSBub25jZQ=="
                    },
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_HEADER_FIELD",
                        payload = "Sec-WebSocket-Version"
                    },
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADER_VALUE", payload = "13"},
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADERS_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = ""}
                }
                assertEquals(numEventsAfter, #expectedEventList)
                assertEquals(bufferSizeAfter, parser:GetNumBufferedEvents() * ffi.sizeof("llhttp_event_t"))
                assertEquals(eventListAfter, expectedEventList)
            end)

        it(
            "should add all events to the buffer if any were triggered and the buffer is not empty",
            function()
                local parser = IncrementalHttpParser()

				local cdataEvent = ffi.new("llhttp_event_t")
                parser:AddBufferedEvent(cdataEvent)

				parser:ParseNextChunk(websocketsRequestString)

                local numEventsAfter = parser:GetNumBufferedEvents()
                local bufferSizeAfter = parser:GetEventBufferSize()
                local eventListAfter = parser:GetBufferedEvents()

				local expectedEventList = {
                    {eventID = "HTTP_EVENT_BUFFER_TOO_SMALL", payload = ""},
                    {eventID = "HTTP_ON_MESSAGE_BEGIN", payload = ""},
                    {eventID = "HTTP_ON_METHOD", payload = "GET"},
                    {eventID = "HTTP_ON_METHOD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_URL", payload = "/chat"},
                    {eventID = "HTTP_ON_URL_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_VERSION", payload = "1.1"},
                    {eventID = "HTTP_ON_VERSION_COMPLETE", payload = ""},
                    {eventID = "HTTP_HEADER_FIELD", payload = "Host"},
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_ON_HEADER_VALUE",
                        payload = "example.com:8000"
                    },
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {eventID = "HTTP_HEADER_FIELD", payload = "Upgrade"},
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADER_VALUE", payload = "websocket"},
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {eventID = "HTTP_HEADER_FIELD", payload = "Connection"},
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADER_VALUE", payload = "Upgrade"},
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_HEADER_FIELD",
                        payload = "Sec-WebSocket-Key"
                    },
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_ON_HEADER_VALUE",
                        payload = "dGhlIHNhbXBsZSBub25jZQ=="
                    },
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {
                        eventID = "HTTP_HEADER_FIELD",
                        payload = "Sec-WebSocket-Version"
                    },
                    {eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADER_VALUE", payload = "13"},
                    {eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_HEADERS_COMPLETE", payload = ""},
                    {eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = ""}
                }

				assertEquals(numEventsAfter, #expectedEventList)
                assertEquals(bufferSizeAfter, parser:GetNumBufferedEvents() * ffi.sizeof("llhttp_event_t"))
                assertEquals(eventListAfter, expectedEventList)

            end)

    end)

    describe("GetNumBufferedEvents", function()
        local parser = IncrementalHttpParser()
        it("should return zero if no events have been buffered yet",
           function() assertEquals(parser:GetNumBufferedEvents(), 0) end)

        it(
            "should return the number of events in the buffer if at least one has been added",
            function()
                local event = ffi.new("llhttp_event_t")
                parser:AddBufferedEvent(event)
                assertEquals(parser:GetNumBufferedEvents(), 1)
                parser:AddBufferedEvent(event)
                assertEquals(parser:GetNumBufferedEvents(), 2)
                parser:AddBufferedEvent(event)
                assertEquals(parser:GetNumBufferedEvents(), 3)
            end)
    end)

    describe("GetEventBufferSize", function()
        local parser = IncrementalHttpParser()
        it("should return zero if no events have been buffered yet",
           function() assertEquals(parser:GetEventBufferSize(), 0) end)

        it(
            "should return the size of the event buffer if at least one event has been added",
            function()
                local event = ffi.new("llhttp_event_t")
                parser:AddBufferedEvent(event)
                assertEquals(parser:GetEventBufferSize(),
                             ffi.sizeof("llhttp_event_t"))
                parser:AddBufferedEvent(event)
                assertEquals(parser:GetEventBufferSize(), ffi.sizeof(
                                 "llhttp_event_t") *
                                 parser:GetNumBufferedEvents())
            end)
    end)

    describe("CreateLuaEvent", function()
		it("should return an equivalent Lua table if a llhttp_event_t was passed", function()
			local parser = IncrementalHttpParser()
			local cEvent = ffi.new("llhttp_event_t")
			local luaEvent = parser:CreateLuaEvent(cEvent)

			assertEquals(luaEvent.eventID, "HTTP_EVENT_BUFFER_TOO_SMALL")
			assertEquals(luaEvent.payload, "")
		end)
	end)

    describe("GetMaxRequiredBufferSize", function()
		local parser = IncrementalHttpParser()
		it("should return zero if an empty string was passed", function()
			assertEquals(parser:GetMaxRequiredBufferSize(""), 0)
		end)

		it("should return a defensive upper-bound based on the chunk size", function()
			-- This clearly is too wasteful, but it's difficult to say how many events will be triggered in advance (mainly due to headers)
			local chunk = websocketsRequestString
			local expectedUpperBound = 2703
			-- local expectedUpperBound = #chunk * ffi.sizeof("llhttp_event_t")
			assertEquals(parser:GetMaxRequiredBufferSize(chunk), expectedUpperBound)

		end)
	end)

	-- TODO
    describe("ClearBufferedEvents", function() end)
    describe("ReplayBufferedEvents", function() end)
    describe("ReplayEvent", function() end)

    describe("GetBufferedMessage", function() end)
    describe("ResetBufferedMessage", function() end)
end)
