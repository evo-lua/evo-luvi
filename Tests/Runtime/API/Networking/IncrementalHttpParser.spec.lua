local IncrementalHttpParser = C_Networking.IncrementalHttpParser

local llhttp = require("llhttp")
local ffi = require("ffi")

local llhttp_get_max_url_length = llhttp.bindings.llhttp_get_max_url_length
local llhttp_get_max_status_length = llhttp.bindings.llhttp_get_max_status_length
local llhttp_get_max_header_key_length = llhttp.bindings.llhttp_get_max_header_key_length
local llhttp_get_max_header_value_length = llhttp.bindings.llhttp_get_max_header_value_length
local llhttp_get_max_body_length = llhttp.bindings.llhttp_get_max_body_length

local ffi_string = ffi.string
local ffi_sizeof = ffi.sizeof

-- There are two things to consider when passing extremely long inputs: NO SEGFAULT and no read-fault (buffer overflow) in memcpy
-- The first would crash and therefore fail the tests, but the second might not - so assert that ONLY the passed in bytes are read
local OVERLY_LONG_URL = string.rep("a", tonumber(llhttp_get_max_url_length()) + 12345)
local OVERLY_LONG_STATUS = string.rep("a", tonumber(llhttp_get_max_status_length()) + 12345)
local OVERLY_LONG_HEADER_KEY = string.rep("a", tonumber(llhttp_get_max_header_key_length()) + 12345)
local OVERLY_LONG_HEADER_VALUE = string.rep("a", tonumber(llhttp_get_max_header_value_length()) + 12345)
local OVERLY_LONG_BODY_STRING = string.rep("a", tonumber(llhttp_get_max_body_length()) + 12345)
-- too many headers (>32)


local testCases = {
	["an invalid message"] = {
		chunk = "asdf",
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = false,
		expectedErrorReason = "Invalid method encountered",
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_minor = 0,
			version_major = 0,
			status_code = 0,
			status_length = 0,
			status = "",
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
			version_minor = 0,
			version_major = 0,
			status_code = 0,
			status_length = 0,
			status = "",
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
			version_minor = 0,
			version_major = 0,
			status_code = 0,
			status_length = 0,
			status = "",
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
			is_complete = true,
			method_length = 3,
			method = "GET",
			url_length = 12,
			url = "/hello-world",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
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
			is_complete = true,
			method_length = 3,
			method = "GET",
			url_length = 12,
			url = "/hello-world",
			version_minor = 0,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
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
		chunk = "HTTP/1.1 200 OK\r\n\r\n",
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
			version_minor = 1,
			version_major = 1,
			status_code = 200,
			status_length = 2,
			status = "OK",
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
		expectedErrorReason = "Pause on CONNECT/Upgrade",
		message = {
			is_complete = true,
			method_length = 3,
			method = "GET",
			url_length = 5,
			url = "/chat",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
			num_headers = 5,
			headers = {
				{ key_length = 4, key = "Host", value_length = #"example.com:8000", value = "example.com:8000"},
				{ key_length = #"Upgrade", key = "Upgrade", value_length = #"websocket", value = "websocket"},
				{ key_length = #"Connection", key = "Connection", value_length = #"Upgrade", value = "Upgrade"},
				{ key_length = #"Sec-WebSocket-Key", key = "Sec-WebSocket-Key", value_length = #"dGhlIHNhbXBsZSBub25jZQ==", value = "dGhlIHNhbXBsZSBub25jZQ=="},
				{ key_length = #"Sec-WebSocket-Version", key = "Sec-WebSocket-Version", value_length = 2, value = "13"},
			},
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
		expectedErrorReason = "Pause on CONNECT/Upgrade",
		message = {
			is_complete = true,
			method_length = 7,
			method = "OPTIONS",
			url_length = 1,
			url = "*",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
			num_headers = 3,
			headers = {
				{ key_length = 4, key = "Host", value_length = #"example.bank.com", value = "example.bank.com"},
				{ key_length = #"Upgrade", key = "Upgrade", value_length = #"TLS/1.0", value = "TLS/1.0"},
				{ key_length = #"Connection", key = "Connection", value_length = #"Upgrade", value = "Upgrade"},
			},
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
		expectedErrorReason = "Invalid method encountered",
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
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
		expectedErrorReason = "Invalid method encountered",
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_minor = 0,
			version_major = 0,
			status_code = 0,
			status_length = 0,
			status = "",
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
		expectedErrorReason = "Invalid method encountered",
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
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
		expectedErrorReason = "Invalid method encountered",
		message = {
			is_complete = false,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_minor = 0,
			version_major = 0,
			status_code = 0,
			status_length = 0,
			status = "",
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
		chunk = "HTTP/1.1 204 No Content\r\nConnection: Keep-Alive\r\n\r\n",
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = true,
		shouldKeepConnectionAlive = true,
		message = {
			is_complete = true,
			method_length = 0,
			method = "",
			url_length = 0,
			url = "",
			version_minor = 1,
			version_major = 1,
			status_code = 204,
			status_length = 10,
			status = "No Content",
			num_headers = 1,
			headers = {
				{
					key_length = #"Connection",
					key = "Connection",
					value_length = #"Keep-Alive",
					value = "Keep-Alive",
				}
			},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a valid message that arrives in many different chunks"] = {
		chunks = {
			"G","E",
			"T /c",
			"hat H",
			"TTP/1.1\r",
			"\nHo","st: ex","ample.com:8000\r\nUp","gra","de: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n",
			-- todo add multi chunk body
		},
		isOK = true,
		isExpectingUpgrade = true,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		expectedErrorReason = "Pause on CONNECT/Upgrade",
		message = {
			is_complete = true,
			method_length = 3,
			method = "GET",
			url_length = 5,
			url = "/chat",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
			num_headers = 5,
			headers = {
				{ key_length = 4, key = "Host", value_length = #"example.com:8000", value = "example.com:8000"},
				{ key_length = #"Upgrade", key = "Upgrade", value_length = #"websocket", value = "websocket"},
				{ key_length = #"Connection", key = "Connection", value_length = #"Upgrade", value = "Upgrade"},
				{ key_length = #"Sec-WebSocket-Key", key = "Sec-WebSocket-Key", value_length = #"dGhlIHNhbXBsZSBub25jZQ==", value = "dGhlIHNhbXBsZSBub25jZQ=="},
				{ key_length = #"Sec-WebSocket-Version", key = "Sec-WebSocket-Version", value_length = 2, value = "13"},
			},
			body_length = 0,
			body = "",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	["a valid message that splits the body into different chunks"] = {
		chunks = {
			"G","E",
			"T /c",
			"hat H",
			"TTP/1.1\r",
			"\nCont","ent-Length: 11","\r\n\r\nhell",
			"o", " kitty\r\n\r\n"
		},
		isOK = true,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		message = {
			is_complete = true,
			method_length = 3,
			method = "GET",
			url_length = 5,
			url = "/chat",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
			num_headers = 1,
			headers = {
				{ key_length = #"Content-Length", key = "Content-Length", value_length = 2, value = "11"},
			},
			body_length = 11,
			body = "hello kitty",
			extended_payload_buffer = {
				ptr = nil,
				size = 0,
				used = 0,
			},
		},
	},
	--status
	-- method?
	-- chunked body
	-- llhttp_interpret_message
	-- message body (buffered), streaming = separate issue = store in LJ buffer?
	["a request with an url string that is too large to buffer"] = {
		chunks = {
			"G","E",
			"T /",
			OVERLY_LONG_URL,
			" H",
			"TTP/1.1\r",
			"\nCont","ent-Length: 11","\r\n\r\nhell",
			"o", " kitty\r\n\r\n"
		},
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		expectedErrorReason = "414 URI Too Long",
		message = {
			is_complete = false,
			method_length = 3,
			method = "GET",
			url_length = 1,
			url = "/",
			version_minor = 0,
			version_major = 0,
			status_code = 0,
			status_length = 0,
			status = "",
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
	["a message with a header key that is too large to buffer"] = {
		chunks = {
			"G","E",
			"T /",
			" H",
			"TTP/1.1\r",
			"\n",
			OVERLY_LONG_HEADER_KEY,
			": 11","\r\n\r\nhell",
			"o", " kitty\r\n\r\n"
		},
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		expectedErrorReason = "431 Request Header Fields Too Large",
		message = {
			is_complete = false,
			method_length = 3,
			method = "GET",
			url_length = 1,
			url = "/",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
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
	["a message with a header value that is too large to buffer"] = {
		chunks = {
			"GET / HTTP/1.1\r\n",
			"Origin: ",
			OVERLY_LONG_HEADER_VALUE,
			"\r\n\r\n"
		},
		isOK = false,
		isExpectingUpgrade = false,
		isExpectingEOF = false,
		shouldKeepConnectionAlive = true,
		expectedErrorReason = "431 Request Header Fields Too Large",
		message = {
			is_complete = false,
			method_length = 3,
			method = "GET",
			url_length = 1,
			url = "/",
			version_minor = 1,
			version_major = 1,
			status_code = 0,
			status_length = 0,
			status = "",
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

}


describe("IncrementalHttpParser", function()
	describe("ParseNextChunk", function()


	for label, testCase in pairs(testCases) do
		it("should return the expected result when " .. label .. " was passed", function()
			local parser = IncrementalHttpParser()

			local message
			for index, chunk in ipairs(testCase.chunks or { testCase.chunk }) do
				message = parser:ParseNextChunk(chunk)
			end

			local expectedState = testCase.isOK
			local actualState = parser:IsOK()
			assertEquals(actualState, expectedState)

			local expectedErrorString = testCase.expectedErrorReason
			local actualErrorString = parser:GetLastError()
			assertEquals(actualErrorString, expectedErrorString)

			assertEquals(message.is_complete, testCase.message.is_complete)

			if ffi_string(message.method, message.method_length) ~= "HTTP/" then
				-- llhttp can't do a better job at differentiating between requests and responses for the first few tokens...
				assertEquals(message.method_length, testCase.message.method_length)
				assertEquals(ffi_string(message.method, message.method_length), testCase.message.method)
			end
			assertEquals(message.status_code, testCase.message.status_code)
			assertEquals(ffi_string(message.status, message.status_length), testCase.message.status)
			assertEquals(message.status_length, testCase.message.status_length)
			assertEquals(ffi_string(message.url, message.url_length), testCase.message.url)
			assertEquals(message.url_length, testCase.message.url_length)
			assertEquals(message.version_major, testCase.message.version_major)
			assertEquals(message.version_minor, testCase.message.version_minor)
			assertEquals(message.num_headers, testCase.message.num_headers)
			assertEquals(message.num_headers, #testCase.message.headers)

			for index=1, message.num_headers, 1 do
				local cIndex = index - 1
				if testCase.message.headers and testCase.message.headers[index] then
					assertEquals(ffi_string(message.headers[cIndex].key, message.headers[cIndex].key_length), testCase.message.headers[index].key)
					assertEquals(ffi_string(message.headers[cIndex].value, message.headers[cIndex].value_length), testCase.message.headers[index].value)
				end
			end

			assertEquals(ffi_string(message.body, message.body_length), testCase.message.body)
			assertEquals(message.body_length, testCase.message.body_length)
			-- -- TBD ext payload

		end)
	end

	-- todo very large req body


-- empty string
-- split message in several chunks (test for each field!!)

		-- Fixed-size structs
-- URL length exceeded
		-- it("should truncate overly-long request URLs after the maximum length has been reached", function()
		-- 	local parser = IncrementalHttpParser()
		-- 	local maxLength = llhttp_get_max_url_length()
		-- 	local longURL = "/asdf"
		-- 	local chunk = "GET " .. longURL .. " HTTP/1.1\r\nOrigin: example.org\r\nConnection: close\r\nContent-Length: 5\r\n\r\nhello\r\n\r\n"
		-- 	local message = parser:ParseNextChunk(chunk)

		-- end)
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




	-- tbd some stuff can be read from llhttp apis
		-- TODO response
		-- isUpgradeRequest, status, reason etc. handled by llhttp?
		-- exceeds max size (for each field) -> HPE_ERROR / HPE_USER
		it("should return a HTTP message with the request details", function()
			local parser = IncrementalHttpParser()
			local chunk = "GET / HTTP/1.1\r\nOrigin: example.org\r\nConnection: close\r\nContent-Length: 5\r\n\r\nhello\r\n\r\n"
			local message = parser:ParseNextChunk(chunk)
			assertEquals(ffi_string(message.method), "GET")
			assertEquals(ffi_string(message.url), "/")
			assertEquals(tonumber(message.version_major), 1)
			assertEquals(tonumber(message.version_minor), 1)
			assertEquals(tonumber(message.num_headers), 3)
			assertEquals(ffi_string(message.headers[0].key), "Origin")
			assertEquals(ffi_string(message.headers[0].value), "example.org")
			assertEquals(ffi_string(message.headers[1].key), "Connection")
			assertEquals(ffi_string(message.headers[1].value), "close")
			assertEquals(ffi_string(message.headers[2].key), "Content-Length")
			assertEquals(ffi_string(message.headers[2].value), "5")
			assertEquals(ffi_string(message.body), "hello")
		end)
	end)

	-- describe("IsMessageComplete", function()
	-- 	-- TODO
	-- end)

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