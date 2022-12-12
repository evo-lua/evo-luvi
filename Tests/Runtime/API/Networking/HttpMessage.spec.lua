local HttpMessage = require("HttpMessage")

local function createRequestWithHeadersAndBody()
	local message = HttpMessage()
	message.requestTarget:set("/joyent/http-parser")
	message.httpVersion:set("HTTP/1.1")
	message.method:set("POST")

	local expectedHeaders = {
		{ ["Host"] = "github.com" },
		{ ["DNT"] = "1" },
		{ ["Accept-Encoding"] = "gzip, deflate, sdch" },
		{ ["Accept-Language"] = "ru-RU,ru;q=0.8,en-US;q=0.6,en;q=0.4" },
		{
			["User-Agent"] = "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_10_1) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/39.0.2171.65 Safari/537.36",
		},
		{ ["Accept"] = "text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8" },
		{ ["Referer"] = "https://github.com/joyent/http-parser" },
		{ ["Connection"] = "keep-alive" },
		{ ["Transfer-Encoding"] = "chunked" },
		{ ["Cache-Control"] = "max-age=0" },
	}
	for index, keyValuePair in ipairs(expectedHeaders) do
		for key, value in pairs(keyValuePair) do
			table.insert(message.headers, { key, value })
		end
	end

	message.body:set("\r\nb\r\nhello world\r\n0")

	return message
end

local function createResponseWithHeadersAndBody()
	local message = HttpMessage()
	message.httpVersion:set("HTTP/1.1")
	message.statusCode:set("200")
	message.reasonPhrase:set("OK")

	local expectedHeaders = {
		{ ["Host"] = "example.org" },
		{ ["Acess-Control-Allow-Origin"] = "*" },
	}
	for index, keyValuePair in ipairs(expectedHeaders) do
		for key, value in pairs(keyValuePair) do
			table.insert(message.headers, { key, value })
		end
	end

	message.body:set("HELLO! HELLO! HELLO!")

	return message
end

describe("HttpMessage", function()
	describe("Construct", function()
		it("should initialize all fields with an empty string buffer", function()
			local message = HttpMessage()

			assertEquals(message.method, "")
			assertEquals(message.requestTarget, "")
			assertEquals(message.httpVersion, "")

			assertEquals(message.statusCode, "")
			assertEquals(message.reasonPhrase, "")

			assertEquals(message.headers, {}) -- Not a string buffer, but oh well...
			assertEquals(message.body, "")
		end)
	end)

	describe("IsEmpty", function()
		it("should return true if no fields have been set and no headers were added", function()
			local message = HttpMessage()
			assertTrue(message:IsEmpty())
		end)

		it("should return false if any fields have been set", function()
			local fields = {
				method = "GET",
				requestTarget = "/downloads",
				httpVersion = "1.1",
				statusCode = "200",
				reasonPhrase = "OK",
				body = "Hello world!",
			}

			for fieldName, exampleValue in pairs(fields) do
				local message = HttpMessage()
				message[fieldName] = exampleValue
				assertFalse(message:IsEmpty())
			end
		end)

		it("should return false if any headers have been added", function()
			local message = HttpMessage()
			message.headers[#message.headers + 1] = "Origin"
			message.headers[#message.headers + 1] = "www.google.com"
			assertFalse(message:IsEmpty())
		end)
	end)

	describe("IsRequest", function()
		it("should return true if all request-specific fields have been set and none of the others", function()
			local message = HttpMessage()
			message.requestTarget:set("/hello-world")
			message.httpVersion:set("HTTP/1.1")
			message.method:set("GET")
			assertTrue(message:IsRequest())
		end)

		it("should return false if some request-specific fields have not been set", function()
			local message = HttpMessage()
			message.requestTarget:set("/hello-world")
			message.httpVersion:set("HTTP/1.1")

			message.method:reset()

			assertFalse(message:IsRequest())
		end)

		it("should return false if any response-specific fields have been set", function()
			local message = HttpMessage()
			message.requestTarget:set("/hello-world")
			message.httpVersion:set("HTTP/1.1")
			message.method:set("GET")

			message.reasonPhrase:set("Something's not quite right")
			assertFalse(message:IsRequest())
		end)
	end)

	describe("IsResponse", function()
		it("should return true if all response-specific fields have been set and none of the others", function()
			local message = HttpMessage()
			message.httpVersion:set("HTTP/1.1")
			message.statusCode:set("200")
			message.reasonPhrase:set("OK")

			assertTrue(message:IsResponse())
		end)

		it("should return false if some mandatory response-specific fields have not been set", function()
			local message = HttpMessage()
			message.statusCode:set("200")
			message.reasonPhrase:set("OK")

			message.httpVersion:reset()

			assertFalse(message:IsResponse())
		end)

		it("should return ture if some optional response-specific fields have not been set", function()
			local message = HttpMessage()
			message.httpVersion:set("HTTP/1.1")
			message.statusCode:set("200")

			message.reasonPhrase:reset()

			assertTrue(message:IsResponse())
		end)

		it("should return false if any request-specific fields have been set", function()
			local message = HttpMessage()
			message.httpVersion:set("HTTP/1.1")
			message.statusCode:set("200")
			message.reasonPhrase:set("OK")

			message.requestTarget:set("/request-target-should-not-be-set-in-a-response")

			assertFalse(message:IsResponse())
		end)
	end)

	describe("ToString", function()
		it("should return an empty string if the message is empty", function()
			local message = HttpMessage()
			assertTrue(message:IsEmpty())

			local expectedRequestString = ""
			assertEquals(message:ToString(), expectedRequestString)
		end)

		it(
			"should return a string representation of the message if it's a valid request without headers and body",
			function()
				local message = HttpMessage()
				message.requestTarget:set("/joyent/http-parser")
				message.httpVersion:set("HTTP/1.1")
				message.method:set("POST")

				assertTrue(message:IsRequest())

				local expectedRequestString = "POST /joyent/http-parser HTTP/1.1\r\n\r\n"
				assertEquals(message:ToString(), expectedRequestString)
			end
		)

		it(
			"should return a string representation of the message if it's a valid request with headers and body",
			function()
				local message = createRequestWithHeadersAndBody()
				assertTrue(message:IsRequest())

				local expectedRequestString = "POST /joyent/http-parser HTTP/1.1\r\n"
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
				assertEquals(message:ToString(), expectedRequestString)
			end
		)

		it(
			"should return a string representation of the message if it's a valid response without headers or body",
			function()
				local message = HttpMessage()
				message.httpVersion:set("HTTP/1.1")
				message.statusCode:set("200")
				message.reasonPhrase:set("OK")

				assertTrue(message:IsResponse())

				local expectedRequestString = "HTTP/1.1 200 OK\r\n\r\n"
				assertEquals(message:ToString(), expectedRequestString)
			end
		)

		it(
			"should return a string representation of the message if it's a valid response with headers and body",
			function()
				local message = createResponseWithHeadersAndBody()

				assertTrue(message:IsResponse())

				local expectedRequestString =
					"HTTP/1.1 200 OK\r\nHost: example.org\r\nAcess-Control-Allow-Origin: *\r\nHELLO! HELLO! HELLO!\r\n\r\n"
				assertEquals(message:ToString(), expectedRequestString)
			end
		)
	end)

	describe("Reset", function()
		it("should have no effect if the message is empty", function()
			local emptyMessage = HttpMessage()
			assertTrue(emptyMessage:IsEmpty())
			emptyMessage:Reset()
			assertTrue(emptyMessage:IsEmpty())
		end)

		it("should reset all request fields if any have been modified", function()
			local message = createRequestWithHeadersAndBody()

			assertFalse(message:IsEmpty())
			message:Reset()
			assertTrue(message:IsEmpty())
		end)

		it("should reset all response fields if any have been modified", function()
			local message = createResponseWithHeadersAndBody()

			assertFalse(message:IsEmpty())
			message:Reset()
			assertTrue(message:IsEmpty())
		end)
	end)
end)
