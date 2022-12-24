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
			-- char method[16];
			-- char uri[256];
			-- char http_version[16];
			-- struct {
			--   char name[256];
			--   char value[4096];
			-- } headers[MAX_HEADERS];
			-- size_t num_headers;
			-- char body[4096];
			assertEquals(ffi_string(message.method), "GET")
			assertEquals(ffi_string(message.uri), "/")
			assertEquals(ffi_string(message.http_version), "1.1")
			assertEquals(tonumber(message.num_headers), 4)
			assertEquals(ffi_string(message.headers[0].name), "Origin")
			assertEquals(ffi_string(message.headers[0].value), "example.org")
			assertEquals(ffi_string(message.headers[1].name), "Connection")
			assertEquals(ffi_string(message.headers[1].value), "close")
			assertEquals(message.body, "hello")
		end)
	end)
end)