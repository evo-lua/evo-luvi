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

local websocketsRequestString =
	"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"

local websocketsRequestStrings = {
	"GET /chat HTTP/1.1\r\n",
	"Host: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n",
}

describe("IncrementalHttpRequestParser", function()
	describe("Construct", function()
		local parser = IncrementalHttpRequestParser()
		it("should return nil if the buffered request is not yet finalized", function()
			assertEquals(parser:GetBufferedRequest(), nil)
		end)
	end)

	describe("ParseNextChunk", function()
		local parser = IncrementalHttpRequestParser()
		it("should update the buffered request if a valid HTTP message was parsed in a single chunk", function()
			parser:ParseNextChunk(websocketsRequestString)
			parser:FinalizeBufferedRequest()
			assertEquals(parser:GetBufferedRequest(), websocketsUpgradeRequest)
			dump(parser)
		end)

		it("should update the buffered request if a valid HTTP message was parsed in multiple chunks", function()
			local incompleteRequest = HttpRequest()
			incompleteRequest.method = "GET"
			incompleteRequest.versionString = "HTTP/1.1"
			incompleteRequest.requestedURL = "/chat"

			parser:ParseNextChunk(websocketsRequestStrings[1])
			assertEquals(parser:GetBufferedRequest(), incompleteRequest)
			parser:ParseNextChunk(websocketsRequestStrings[2])
			parser:FinalizeBufferedRequest()
			assertEquals(parser:GetBufferedRequest(), websocketsUpgradeRequest)
		end)
	end)

	-- describe("GetBufferedRequest", function() end)

	describe("ResetInternalState", function()
		it("should re-initialize the parser with an empty request cache", function()
			local parser = IncrementalHttpRequestParser()
			parser:ParseNextChunk(websocketsRequestString)
			-- parser:ResetInternalState()
			assertEquals(parser:GetBufferedRequest(), nil)
		end)
	end)

	-- describe("IsRequestFinished", function()
	-- 	local parser = IncrementalHttpRequestParser()
	-- end)

	-- describe("Flush", function() end)
end)
