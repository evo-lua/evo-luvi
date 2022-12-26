local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")
local ffi = require("ffi")

local llhttp_get_max_url_length = llhttp.bindings.llhttp_get_max_url_length

local ffi_string = ffi.string
local ffi_sizeof = ffi.sizeof

local testCases = {
	["an invalid message"] = {
		chunk = "asdf",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["an incomplete but otherwise valid request"]  = {
		chunk = "POST /hello",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false,
		message = {
			is_complete = false,
			method_length = 4,
			method = "POST",
			url_length = 6,
			url = "/hello",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["an incomplete but otherwise valid response"]  = {
		chunk = "HTTP/1",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true, -- The client should wait for the server's EOF, which can end the message at any time (RFC2616, 4.4.5)
		shouldKeepConnectionAlive = false,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 6,
			version = "HTTP/1",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a complete (and valid) HTTP/1.1 request"] = {
		chunk= "GET /hello-world HTTP/1.1\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true, -- Default value for HTTP/1.1
		message = {
			is_complete = false,
			method_length = 3,
			method = "GET",
			url_length = 12,
			url = "/hello-world",
			version_length = 8,
			version = "HTTP/1.1",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a complete (and valid) HTTP/1.0 request"] = {
		chunk= "GET /hello-world HTTP/1.0\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false, -- Default value for HTTP/1.0
		message = {
			is_complete = false,
			method_length = 3,
			method = "GET",
			url_length = 12,
			url = "/hello-world",
			version_length = 8,
			version = "HTTP/1.0",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a complete (and valid) response"] = {
		chunk = "HTTP/1.1 200 OK",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true,
		shouldKeepConnectionAlive = false,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 8,
			version = "HTTP/1.1",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a valid WebSockets upgrade request"] = {
		chunk = "GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = true,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a mandatory TLS upgrade request"] = {
		chunk = "OPTIONS * HTTP/1.1\r\nHost: example.bank.com\r\nUpgrade: TLS/1.0\r\nConnection: Upgrade\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = true,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["an invalid message that comes after a valid one"] = {
		chunk = "GET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\n",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,  -- HTTP/1.1 default
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a valid message that comes after an invalid one"] = {
		chunk = "asadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\n",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false, -- Due to the initial error state, llhttp discards the second message
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["an invalid message that arrives between two valid ones"] = {
		chunk = "GET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\n",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true, -- HTTP/1.1 default
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a valid message that arrives between two invalid ones"] = {
		chunk = "asadfasfthisisnotvalidatall\r\n\r\nGET /hello-world HTTP/1.1\r\n\r\nasadfasfthisisnotvalidatall\r\n\r\n",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a response with Connection: Keep-Alive header"] = {
		chunk = "HTTP/1.1 200 OK\r\nConnection: Keep-Alive\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true,
		shouldKeepConnectionAlive = false,
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_length = 0,
			version = "",
			num_headers = 0,
			headers = {},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	}
}


describe("IncrementalHttpParser", function()
	describe("ParseNextChunk", function()


	for label, testCase in pairs(testCases) do
		it("should return the expected result when " .. label .. " was passed", function()
			local parser = IncrementalHttpParser()
			local message = parser:ParseNextChunk(testCase.chunk)
			-- assertEquals(parser:IsOK(), testCase.isOK)

			assertEquals(message.is_complete, testCase.message.is_complete)
			-- assertEquals(message.method_length, testCase.message.message_length)
			-- assertEquals(message.method, testCase.message.method)
			-- assertEquals(message.url_length, testCase.message.url_length)
			-- assertEquals(message.url, testCase.message.url)
			-- assertEquals(message.version_length, testCase.message.version_length)
			-- assertEquals(message.version, testCase.message.version)
			-- assertEquals(message.num_headers, testCase.message.num_headers)
			-- assertEquals(message.num_headers, #testCase.message.headers)
			-- -- TBD headers, key values
			-- assertEquals(message.num_body_length, testCase.message.body_length)
			-- assertEquals(message.num_body, testCase.message.body)
			-- -- TBD ext payload

			-- struct {
			-- 	uint8_t key_length;
			-- 	char key[MAX_HEADER_KEY_LENGTH_IN_BYTES];
			-- 	size_t value_length;
			-- 	char value[MAX_HEADER_VALUE_LENGTH_IN_BYTES];
			--   } headers[MAX_HEADER_COUNT];
		end)
	end

	-- todo very large req body


-- empty string
-- split message in several chunks (test for each field!!)

		-- Fixed-size structs
-- URL length exceeded
		it("should truncate overly-long request URLs after the maximum length has been reached", function()
			local parser = IncrementalHttpParser()
			local maxLength = llhttp_get_max_url_length()
			local longURL = "/asdf"
			local chunk = "GET " .. longURL .. " HTTP/1.1\r\nOrigin: example.org\r\nConnection: close\r\nContent-Length: 5\r\n\r\nhello\r\n\r\n"
			local message = parser:ParseNextChunk(chunk)

		end)
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
			assertEquals(ffi_string(message.version), "1.1") -- TODO use llhttp api
			assertEquals(tonumber(message.num_headers), 4)
			assertEquals(ffi_string(message.headers[0].name), "Origin")
			assertEquals(ffi_string(message.headers[0].value), "example.org")
			assertEquals(ffi_string(message.headers[1].name), "Connection")
			assertEquals(ffi_string(message.headers[1].value), "close")
			assertEquals(ffi_string(message.headers[1].name), "Content-Length")
			assertEquals(ffi_string(message.headers[1].value), "5")
			assertEquals(ffi_string(message.body), "hello")
		end)
	end)

	-- describe("IsMessageComplete", function()
	-- 	-- TODO
	-- end)

	-- describe("IsOK", function()

	-- 	for label, testCase in pairs(testCases) do
	-- 		local expectedState = testCase.isOK
	-- 		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
	-- 			local parser = IncrementalHttpParser()

	-- 			parser:ParseNextChunk(testCase.chunk)

	-- 			local actualState = parser:IsOK()
	-- 			assertEquals(actualState, expectedState)
	-- 		end)
	-- 	end

	-- 	it("should return false if a message with an overlong request URL has been parsed", function()
	-- 		-- TODO
	-- 	end)


	-- end)

	-- describe("IsExpectingUpgrade", function()

	-- 	for label, testCase in pairs(testCases) do
	-- 		local expectedState = testCase.isExpectingUpgrade
	-- 		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
	-- 			local parser = IncrementalHttpParser()

	-- 			parser:ParseNextChunk(testCase.chunk)

	-- 			local actualState = parser:IsExpectingUpgrade()
	-- 			assertEquals(actualState, expectedState)
	-- 		end)
	-- 	end

	-- end)

	-- describe("IsExpectingEOF", function()

	-- 	for label, testCase in pairs(testCases) do
	-- 		local expectedState = testCase.isExpectingEOF
	-- 		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
	-- 			local parser = IncrementalHttpParser()

	-- 			parser:ParseNextChunk(testCase.chunk)

	-- 			local actualState = parser:IsExpectingEOF()
	-- 			assertEquals(actualState, expectedState)
	-- 		end)
	-- 	end

	-- end)

	-- describe("ShouldKeepConnectionAlive", function()

	-- 	for label, testCase in pairs(testCases) do
	-- 		local expectedState = testCase.shouldKeepConnectionAlive
	-- 		it("should return " .. tostring(expectedState) .. " after parsing " .. label, function()
	-- 			local parser = IncrementalHttpParser()

	-- 			parser:ParseNextChunk(testCase.chunk)

	-- 			local actualState = parser:ShouldKeepConnectionAlive()
	-- 			assertEquals(actualState, expectedState)
	-- 		end)
	-- 	end

	-- end)


end)