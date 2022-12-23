local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")
local ffi = require("ffi")

local ffi_string = ffi.string

describe("IncrementalHttpParser", function()
	describe("ParseNextChunk", function()
		it("should return a HTTP message with the request details", function()
			local parser = IncrementalHttpParser()
			local chunk = "GET / HTTP/1.1\r\nOrigin: example.org\r\nConnection: close\r\nhello\r\n\r\n"
			local message = parser:ParseNextChunk(chunk)
			assertEquals(message.httpMethod, "GET")
			assertEquals(message.requestTarget, "/")
			assertEquals(message.httpVersion, "1.1")
			assertEquals(message.headers, {
				{ "Origin", "example.org" },
				{ "Connection", "close" },
			})
			assertEquals(message.body, "hello")
		end)
	end)
end)