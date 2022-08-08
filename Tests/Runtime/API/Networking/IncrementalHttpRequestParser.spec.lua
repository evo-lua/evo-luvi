local HttpRequest = C_Networking.HttpRequest
local IncrementalHttpRequestParser = C_Networking.IncrementalHttpRequestParser

local websocketsUpgradeRequest = {
	method = "GET",
	requestedURL = "/chat",
	versionString = "HTTP/1.1",
	headers = {
		["Host"] = "example.com:8000",
		["Upgrade"] = "websocket",
		["Connection"] = "Upgrade",
		["Sec-WebSocket-Key"] = "dGhlIHNhbXBsZSBub25jZQ==",
		["Sec-WebSocket-Version"] = "13",
		[1] = "Host",
		[2] = "Upgrade",
		[3] = "Connection",
		[4] = "Sec-WebSocket-Key",
		[5] = "Sec-WebSocket-Version",
	},
	body = {},
}

describe("IncrementalHttpRequestParser", function()
	local defaultRequest = HttpRequest()
	describe("Construct", function()
		local parser = IncrementalHttpRequestParser()
		it("should initialize the parser with a empty request cache", function()
			assertEquals(parser:GetCachedRequest(), defaultRequest)
		end)
	end)

	describe("ParseNextChunk", function()
		local parser = IncrementalHttpRequestParser()
		it("should update the cached request if a valid HTTP message was parsed in a single chunk", function()
			local websocketsRequestString =
				"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
			parser:ParseNextChunk(websocketsRequestString)
			assertEquals(parser:GetCachedRequest(), websocketsUpgradeRequest)
		end)

		it("should update the cached request if a valid HTTP message was parsed in multiple chunks", function()
			local websocketsRequestStrings = {
				"GET /chat HTTP/1.1\r\n",
				"Host: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n",
			}

			local incompleteRequest = HttpRequest()
			incompleteRequest.method = "GET"
			incompleteRequest.versionString = "HTTP/1.1"
			incompleteRequest.requestedURL = "/chat"

			parser:ParseNextChunk(websocketsRequestStrings[1])
			assertEquals(parser:GetCachedRequest(), incompleteRequest)
			parser:ParseNextChunk(websocketsRequestStrings[2])
			assertEquals(parser:GetCachedRequest(), websocketsUpgradeRequest)
		end)
	end)

	describe("GetCachedRequest", function() end)

	describe("ResetInternalState", function()
		local parser = IncrementalHttpRequestParser()
		it("should re-initialize the parser with an empty request cache")
	end)

	describe("IsRequestFinished", function()
		local parser = IncrementalHttpRequestParser()
	end)

	describe("Flush", function() end)
end)