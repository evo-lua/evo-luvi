local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")
local ffi = require("ffi")

local ffi_string = ffi.string

-- Fixed-size structs
-- URL length exceeded
-- status (reason phrase) exceeded
--header field length exceeded
-- header value length exceeded
-- too many headers
-- body length exceeded
-- Dynamic-size structs (pre-allocated from Lua)
-- body is replaced with string buffer reference
-- Buffering mode: Body is held in memory
-- Streaming mode: Body is outsourced to file
-- body is moved to file (in Lua) -> sbuf gets and then stream to open fd -> buf should be empty, file should have body
-- HAPPY PATH: ws upgrade req, upgrade response, split in two chunks, all the other test cases (valid/invalid msg interleaved), req/resp interleaved

describe("IncrementalHttpParser", function()
	describe("ParseNextChunk", function()

		-- TODO response
		-- TODO isCompleted flag
		-- isUpgradeRequest, status, reason etc. handled by llhttp?
		-- exceeds max size (for each field) -> HPE_ERROR / HPE_USER
		it("should return a HTTP message with the request details", function()
			local parser = IncrementalHttpParser()
			local chunk = "GET / HTTP/1.1\r\nOrigin: example.org\r\nConnection: close\r\nContent-Length: 5\r\n\r\nhello\r\n\r\n"
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
			assertEquals(ffi_string(message.method), "GET") -- TODO use llhttp api
			assertEquals(ffi_string(message.url), "/")
			-- assertEquals(ffi_string(message.http_version), "1.1") -- TODO use llhttp api
			-- assertEquals(tonumber(message.num_headers), 4)
			-- assertEquals(ffi_string(message.headers[0].name), "Origin")
			-- assertEquals(ffi_string(message.headers[0].value), "example.org")
			-- assertEquals(ffi_string(message.headers[1].name), "Connection")
			-- assertEquals(ffi_string(message.headers[1].value), "close")
			-- assertEquals(ffi_string(message.headers[1].name), "Content-Length")
			-- assertEquals(ffi_string(message.headers[1].value), "5")
			assertEquals(ffi_string(message.body), "hello")
		end)
	end)
end)