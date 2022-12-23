local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")
local ffi = require("ffi")

local ffi_string = ffi.string

local function assertEventInfoMatches(actualEvents, expectedEvents)
	for index, actualEvent in ipairs(actualEvents) do
		local expectedEvent = expectedEvents[index]
		assertEquals(llhttp.FFI_EVENTS[tonumber(actualEvent.event_id)], expectedEvent.eventID)
		assertEquals(ffi_string(actualEvent.payload_start_pointer, actualEvent.payload_length), expectedEvent.payload)
	end
end

local function assertRecordedCallbacksMatch(message, expectedEventList)
	local parser = IncrementalHttpParser()
	local stringBuffer = parser:ParseChunkAndRecordCallbackEvents(message)

	local eventList = C_Networking.DecodeBufferAsArrayOf(stringBuffer, "llhttp_event_t")
	assertEventInfoMatches(eventList, expectedEventList)
end

local expectedCallbackEventsOnInput = {
	["POST /hello"] = {
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		{ eventID = "HTTP_ON_METHOD", payload = "POST" },
		{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_URL", payload = "/hello" },
	},
	["GET /hello-world HTTP/1.1\r\n\r\n"] = {
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		{ eventID = "HTTP_ON_METHOD", payload = "GET" },
		{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_URL", payload = "/hello-world" },
		{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
		{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
	},
	["HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello"] = {
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		{ eventID = "HTTP_ON_METHOD", payload = "HTTP/" }, -- METHOD never completes because the parser switches to REPONSE mode here
		{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
		{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_STATUS", payload = "OK" },
		{ eventID = "HTTP_ON_STATUS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADER_FIELD", payload = "Content-Length" },
		{ eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADER_VALUE", payload = "5" },
		{ eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_BODY", payload = "Hello" },
		{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
	},
	["GET /hello-world HTTP/1.1\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\n"] = {
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		{ eventID = "HTTP_ON_METHOD", payload = "GET" },
		{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_URL", payload = "/hello-world" },
		{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
		{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_RESET", payload = "" }, -- This is really the only relevant part here as it allows us to reset the buffer
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		{ eventID = "HTTP_ON_METHOD", payload = "GET" },
		{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_URL", payload = "/hello-world" },
		{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
		{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
	},
	["HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHelloHTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello"] = {
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		{ eventID = "HTTP_ON_METHOD", payload = "HTTP/" }, -- METHOD never completes because the parser switches to REPONSE mode here
		{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
		{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_STATUS", payload = "OK" },
		{ eventID = "HTTP_ON_STATUS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADER_FIELD", payload = "Content-Length" },
		{ eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADER_VALUE", payload = "5" },
		{ eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_BODY", payload = "Hello" },
		{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_RESET", payload = "" }, -- This is really the only relevant part here as it allows us to reset the buffer
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
		 -- METHOD doesn't occur again because the parser has already switched to REPONSE mode the first time around
		{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
		{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_STATUS", payload = "OK" },
		{ eventID = "HTTP_ON_STATUS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADER_FIELD", payload = "Content-Length" },
		{ eventID = "HTTP_ON_HEADER_FIELD_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADER_VALUE", payload = "5" },
		{ eventID = "HTTP_ON_HEADER_VALUE_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
		{ eventID = "HTTP_ON_BODY", payload = "Hello" },
		{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
	},
	["GET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\n"] = {
		{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
			{ eventID = "HTTP_ON_METHOD", payload = "GET" },
			{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_URL", payload = "/hello-world" },
			{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
			{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_RESET", payload = "" },
			{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" }, -- After this, the parser is in an error state = no more events
	},
	["asadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\n"] = {
			-- The parser is in an error state initially, so there's no events until a valid message begins
			{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
			{ eventID = "HTTP_ON_METHOD", payload = "GET" },
			{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_URL", payload = "/hello-world" },
			{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
			{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
	},
	["asadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\n"] = {
			-- The parser is in an error state, so there's no events until a valid message begins
			{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
			{ eventID = "HTTP_ON_METHOD", payload = "GET" },
			{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_URL", payload = "/hello-world" },
			{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
			{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
			-- The invalid message again triggers no events (but sets the error state)
	},
}

local testCases = {
	["an invalid message"] = {
		chunk = "asdf",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false,
	},
	["an incomplete but otherwise valid request"]  = {
		chunk = "POST /hello",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false,
	},
	["an incomplete but otherwise valid response"]  = {
		chunk = "HTTP/1",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true, -- The client should wait for the server's EOF, which can end the message at any time (RFC2616, 4.4.5)
		shouldKeepConnectionAlive = false,
	},
	["a complete (and valid) HTTP/1.1 request"] = {
		chunk= "GET /hello-world HTTP/1.1\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true, -- Default value for HTTP/1.1
	},
	["a complete (and valid) HTTP/1.0 request"] = {
		chunk= "GET /hello-world HTTP/1.0\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false, -- Default value for HTTP/1.0
	},
	["a complete (and valid) response"] = {
		chunk = "HTTP/1.1 200 OK",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true,
		shouldKeepConnectionAlive = false,
	},
	["a valid WebSockets upgrade request"] = {
		chunk = "GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = true,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
	},
	["a mandatory TLS upgrade request"] = {
		chunk = "OPTIONS * HTTP/1.1\r\nHost: example.bank.com\r\nUpgrade: TLS/1.0\r\nConnection: Upgrade\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = true,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
	},
	-- TLS upgrade request
	-- Invalid after valid message
	-- Valid after invalid message
	-- Invalid message between two valid message
	-- Valid message between two invalid ones
	["a response with Connection: Keep-Alive header"] = {
		chunk = "HTTP/1.1 200 OK\r\nConnection: Keep-Alive\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true,
		shouldKeepConnectionAlive = false,
	}
}

describe("IncrementalHttpParser", function()

describe("ParseChunkAndRecordCallbackEvents", function()

	it("should return nil when an empty string was passed", function()
		local parser = IncrementalHttpParser()
		assertEquals(parser:ParseChunkAndRecordCallbackEvents(""), nil)
	end)

	it("should return a list of callback events when a partial message was passed", function()
		local chunk = "POST /hello"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when a message was split and passed as two separate chunks", function()
		local parser = IncrementalHttpParser()
		local stringBufferA = parser:ParseChunkAndRecordCallbackEvents("GET /hello-")
		local stringBufferB = parser:ParseChunkAndRecordCallbackEvents("world HTTP/1.1\r\n\r\n")

		assertEquals(stringBufferA, stringBufferB)

		local expectedEventList = {
			{ eventID = "HTTP_ON_MESSAGE_BEGIN", payload = "" },
			{ eventID = "HTTP_ON_METHOD", payload = "GET" },
			{ eventID = "HTTP_ON_METHOD_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_URL", payload = "/hello-" },
			{ eventID = "HTTP_ON_URL", payload = "world" }, -- This redundancy is one of the "problems" llhttp has due to not buffering
			{ eventID = "HTTP_ON_URL_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_VERSION", payload = "1.1" },
			{ eventID = "HTTP_ON_VERSION_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_HEADERS_COMPLETE", payload = "" },
			{ eventID = "HTTP_ON_MESSAGE_COMPLETE", payload = "" },
		}

		local eventList = C_Networking.DecodeBufferAsArrayOf(stringBufferB, "llhttp_event_t")
	assertEventInfoMatches(eventList, expectedEventList)
	end)

	it("should return a list of callback events when a request was passed as a single chunk", function()
		local chunk = "GET /hello-world HTTP/1.1\r\n\r\n"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when a response was passed as a single chunk", function()
		local chunk = "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when multiple requests were passed in a single chunk", function()
		local chunk = "GET /hello-world HTTP/1.1\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\n"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when multiple responses were passed in a single chunk", function()
	local chunk = "HTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHelloHTTP/1.1 200 OK\r\nContent-Length: 5\r\n\r\nHello"
	assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when a valid message was passed before an invalid one", function()
		local chunk = "GET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\n"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when an invalid message was passed before a valid one", function()
		local chunk = "asadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\n"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

	it("should return a list of callback events when a valid message was passed in between two invalid ones", function()
		local chunk = "asadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\n"
		assertRecordedCallbacksMatch(chunk, expectedCallbackEventsOnInput[chunk])
	end)

end)

-- TBD one per method: IsErrorState, isExpectingUpgrade, isExpectingEOF, shouldKeepAlive
describe("IsOK", function()

	for label, testCase in pairs(testCases) do
		local expectedState = testCase.isOK
		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
			local parser = IncrementalHttpParser()

			parser:ParseChunkAndRecordCallbackEvents(testCase.chunk)

			local actualState = parser:IsOK()
			assertEquals(actualState, expectedState)
		end)
	end

end)

describe("IsExpectingUpgrade", function()

	for label, testCase in pairs(testCases) do
		local expectedState = testCase.isExpectingUpgrade
		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
			local parser = IncrementalHttpParser()

			parser:ParseChunkAndRecordCallbackEvents(testCase.chunk)

			local actualState = parser:IsExpectingUpgrade()
			assertEquals(actualState, expectedState)
		end)
	end

end)

describe("IsExpectingEOF", function()

	for label, testCase in pairs(testCases) do
		local expectedState = testCase.isExpectingEOF
		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
			local parser = IncrementalHttpParser()

			parser:ParseChunkAndRecordCallbackEvents(testCase.chunk)

			local actualState = parser:IsExpectingEOF()
			assertEquals(actualState, expectedState)
		end)
	end

end)

describe("ShouldKeepConnectionAlive", function()

	for label, testCase in pairs(testCases) do
		local expectedState = testCase.shouldKeepConnectionAlive
		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
			local parser = IncrementalHttpParser()

			parser:ParseChunkAndRecordCallbackEvents(testCase.chunk)

			local actualState = parser:ShouldKeepConnectionAlive()
			assertEquals(actualState, expectedState)
		end)
	end

end)



-- describe("ParseChunkAndRecordCallbackEvents", function()
-- it("should ", function() end)
-- errorr state, upgrade state, keepalive, needs eof = parser state

-- expected output:
-- event buffer (string buffer) callback buffer
-- event triggers
-- buffered request/response message buffer

-- convert chunk to serialized event list
-- processEventBuffer -> trigger the actual events
-- listen to events -> collect message
-- error handling, max request size

-- HttpParser.ParseChunkAndRecordCallbackEvents (chunk -> eventQueue/line buffer)
-- HttpParser.ReplayStoredEvents: (eventList -> httpMessage), pass message in payload, also trigger events
-- Http:OnEvent (implementation detail)


local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"

-- https://developer.mozilla.org/en-US/docs/Web/HTTP/Messages#http_responses
local someResponse =
	"HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nConnection: Keep-Alive\r\nContent-Encoding: gzip\r\nKeep-Alive: timeout=5, max=999\r\n\r\n"


	describe("Construct", function()
		local parser = IncrementalHttpParser()

		it("should register handlers for all llhttp-ffi events", function()
			local expectedEventHandlers = llhttp.FFI_EVENTS

			for _, eventID in ipairs(expectedEventHandlers) do
				assertEquals(type(parser[eventID]), "function", "Should register listener for event " .. eventID)
			end

			assertEquals(
				type(parser["HTTP_EVENT_BUFFER_TOO_SMALL"]),
				"function",
				"Should register listener for event " .. "HTTP_EVENT_BUFFER_TOO_SMALL"
			)
		end)
	end)

	describe("GetNumBufferedEvents", function()
		local parser = IncrementalHttpParser()
		it("should return zero if no events have been buffered yet", function()
			assertEquals(parser:GetNumBufferedEvents(), 0)
		end)

		it("should return the number of events in the buffer if at least one has been added", function()
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
		it("should return zero if no events have been buffered yet", function()
			assertEquals(parser:GetEventBufferSize(), 0)
		end)

		it("should return the size of the event buffer if at least one event has been added", function()
			local event = ffi.new("llhttp_event_t")
			parser:AddBufferedEvent(event)
			assertEquals(parser:GetEventBufferSize(), ffi.sizeof("llhttp_event_t"))
			parser:AddBufferedEvent(event)
			assertEquals(parser:GetEventBufferSize(), ffi.sizeof("llhttp_event_t") * parser:GetNumBufferedEvents())
		end)
	end)

	-- describe("CreateLuaEvent", function()
	-- 	it("should return an equivalent Lua table if an llhttp_event_t cdata value was passed", function()
	-- 		local parser = IncrementalHttpParser()
	-- 		local cEvent = ffi.new("llhttp_event_t")
	-- 		local luaEvent = parser:CreateLuaEvent(cEvent)

	-- 		assertEquals(luaEvent.eventID, "HTTP_EVENT_BUFFER_TOO_SMALL")
	-- 		assertEquals(luaEvent.payload, "")
	-- 	end)
	-- end)

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
	describe("ClearBufferedEvents", function() end) -- 	-- ResetEventBuffer (also call self.eventBuffer:reset()?)
	describe("ReplayBufferedEvents", function() end)
	describe("ReplayEvent", function() end)

	describe("GetBufferedMessage", function()
		it("should return an empty message if no chunks have been parsed yet", function()
			local parser = IncrementalHttpParser()
			local message = parser:GetBufferedMessage()

			-- TODO assertTrue(message:IsEmpty())
			assertEquals(message.method, "")
			assertEquals(message.requestTarget, "")
			assertEquals(message.httpVersion, "")

			assertEquals(message.statusCode, "")
			assertEquals(message.reasonPhrase, "")

			assertEquals(message.headers, {})
			assertEquals(message.body, "")

			-- Since all fields are uninitialized, it's neither a request nor a response at this time
			assertFalse(message:IsRequest())
			assertFalse(message:IsResponse())
		end)
	end)

	describe("ResetBufferedMessage", function() end)
end)
