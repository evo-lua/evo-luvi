describe("HttpRequest", function()
	describe("Construct", function()
		it("should initialize a default request object when no parameters were passed", function()
			local request = C_Networking.HttpRequest()
			assertEquals(request.method, "GET")
			assertEquals(request.requestedURL, "/")
			assertEquals(request.versionString, "HTTP/1.1")
			assertEquals(request.headers, {})
			assertEquals(request.body, "")
		end)

		it("should store the given request parameters if a table parameter was passed", function()
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
				},
				body = "",
			}
			local request = C_Networking.HttpRequest(websocketsUpgradeRequest)

			assertEquals(request.method, websocketsUpgradeRequest.method)
			assertEquals(request.requestedURL, websocketsUpgradeRequest.requestedURL)
			assertEquals(request.versionString, websocketsUpgradeRequest.versionString)
			assertEquals(request.body, websocketsUpgradeRequest.body)
			assertEquals(request.headers["Host"], websocketsUpgradeRequest.headers["Host"])
			assertEquals(request.headers["Upgrade"], websocketsUpgradeRequest.headers["Upgrade"])
			assertEquals(request.headers["Connection"], websocketsUpgradeRequest.headers["Connection"])
			assertEquals(request.headers["Sec-WebSocket-Key"], websocketsUpgradeRequest.headers["Sec-WebSocket-Key"])
			assertEquals(
				request.headers["Sec-WebSocket-Version"],
				websocketsUpgradeRequest.headers["Sec-WebSocket-Version"]
			)
		end)
	end)

	describe("ToString", function()
		it("should return the equivalent string representation for the given request object", function()
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
				},
				body = {},
			}
			local request = C_Networking.HttpRequest(websocketsUpgradeRequest)
			local requestString = request:ToString()

			local expectedRequestString =
				"GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
			assertEquals(requestString, expectedRequestString)
		end)
	end)
end)
