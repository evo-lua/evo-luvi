local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")

local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
local nodeRequest1 = "GET /wp-content/uploads/2010/03/hello-kitty-darth-vader-pink.jpg HTTP/1.1\r\n"
	.. "Host: www.kittyhell.com\r\n"
	.. "User-Agent: Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10.6; ja-JP-mac; rv:1.9.2.3) Gecko/20100401 Firefox/3.6.3 Pathtraq/0.9\r\n"
	.. "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8\r\n"
	.. "Accept-Language: ja,en-us;q=0.7,en;q=0.3\r\n"
	.. "Accept-Encoding: gzip,deflate\r\n"
	.. "Accept-Charset: Shift_JIS,utf-8;q=0.7,*;q=0.7\r\n"
	.. "Keep-Alive: 115\r\n"
	.. "Connection: keep-alive\r\n"
	.. "Cookie: wp_ozh_wsa_visits=2; wp_ozh_wsa_visit_lasttime=xxxxxxxxxx; __utma=xxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.xxxxxxxxxx.x; __utmz=xxxxxxxxx.xxxxxxxxxx.x.x.utmccn=(referral)|utmcsr=reader.livedoor.com|utmcct=/reader/|utmcmd=referral\r\n\r\n"
local nodeRequest2 = "POST /joyent/http-parser HTTP/1.1\r\n"
	.. "Host: github.com\r\n"
	.. "DNT: 1\r\n"
	.. "Accept-Encoding: gzip, deflate, sdch\r\n"
	.. "Accept-Language: ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4\r\n"
	.. "User-Agent: Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) "
	.. "AppleWebKit/537.36 (KHTML, like Gecko) "
	.. "Chrome/39.0.2171.65 Safari/537.36\r\n"
	.. "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,"
	.. "image/webp,*/*;q=0.8\r\n"
	.. "Referer: https://github.com/joyent/http-parser\r\n"
	.. "Connection: keep-alive\r\n"
	.. "Transfer-Encoding: chunked\r\n"
	.. "Cache-Control: max-age=0\r\n\r\nb\r\nhello world\r\n0\r\n\r\n"

describe("IncrementalHttpParser", function()
	describe("Construct", function()
		local parser = IncrementalHttpParser()
		it("should initialize an empty event buffer", function()
			local eventBuffer = parser:GetEventBuffer()

			assertEquals(parser:GetNumBufferedEvents(), 0)
			assertEquals(tostring(eventBuffer), "")
			assertEquals(#eventBuffer, 0)

			assertEquals(parser:GetBufferedEvents(), {})
		end)

		-- it("should register event handlers for all llhttp-ffi events", function()
		-- 	local llhttpEvents = llhttp.FFI_EVENTS
		-- 	dump(parser)
		-- 	for index, eventID in ipairs(llhttpEvents) do
		-- 		assertTrue(parser:IsEventRegistered(eventID), eventID)
		-- 	end

		-- 	-- Zero-indexed by design, which means the fallback is skipped by ipairs
		-- 	assertTrue(parser:IsEventRegistered("HTTP_EVENT_BUFFER_TOO_SMALL"), "HTTP_EVENT_BUFFER_TOO_SMALL")
		-- end)

		it("should register handlers for all llhttp-ffi events", function()
			local expectedEventHandlers = llhttp.FFI_EVENTS

			for _, eventID in ipairs(expectedEventHandlers) do
				assertEquals(type(parser[eventID]), "function", "Should register listener for event " .. eventID)
			end

			assertEquals(type(parser["HTTP_EVENT_BUFFER_TOO_SMALL"]), "function", "Should register listener for event " .. "HTTP_EVENT_BUFFER_TOO_SMALL")
		end)
	end)

	describe("ParseNextChunk", function()
		it("should replay all buffered llhttp-ffi events in the order that they were queued in", function()
			local parser = IncrementalHttpParser()
			local chunk = nodeRequest2

			parser:ParseNextChunk(chunk)


			local eventBuffer = parser:GetEventBuffer()
			assertEquals(parser:GetNumBufferedEvents(), 42)
			assertEquals(tostring(eventBuffer), "test")
			assertEquals(#eventBuffer, 42)

			local events = parser:GetBufferedEvents()
			dump(events)



			-- print(type(parser.eventBuffer))
			-- print(parser.state.data)

			-- assertEquals(#parser.eventBuffer, #chunk)
			-- assertEquals(tostring(parser.eventBuffer), chunk)
		end)
	end)
end)