local scenario = C_Testing.Scenario("HTTP 'hello world' server")

local HttpServer = C_Networking.HttpServer
local HttpClient = C_Networking.HttpClient

scenario:GIVEN("A HTTP 'hello world' server is listening on localhost")
scenario:WHEN("A HTTP client sends a basic request")
scenario:THEN("The server should respond with a valid hello world response")

local hasClientSentMessageToServer = false
local hasServerReceivedMessage = false
local hasServerSentResponse = false
local hasClientReceivedEchoMessage = false

function scenario:OnSetup()
	print("OnSetup")
	local serverOptions = {
		port = 1733,
		hostName = "127.0.0.1",
	}
	self.server = HttpServer(serverOptions)
	self.client = HttpClient("127.0.0.1", 1733)
end

function scenario:OnRun()
	print("OnRun")
	local currentThread = coroutine.running()
	local client = self.client

	function client.TCP_CONNECTION_ESTABLISHED()
		-- "GET /chat HTTP/1.1\r\nHost: example.com:8000\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Key: dGhlIHNhbXBsZSBub25jZQ==\r\nSec-WebSocket-Version: 13\r\n\r\n"
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
		client:SendHttpRequest(websocketsUpgradeRequest)
		hasClientSentMessageToServer = true
	end

	function client.HTTP_RESPONSE_RECEIVED(_, response)
		print("HTTP_RESPONSE_RECEIVED")
		assertEquals(response.headers, {})
		assertEquals(response.body, "Hello world!")
		assertEquals(response.statusCode, 200)
		assertEquals(response.statusText, "OK")
		assertEquals(response.versionString, "HTTP/1.1")
		hasClientReceivedEchoMessage = true
		-- The echo test is over, so we can continue with the report
		coroutine.resume(currentThread)
	end

	local server = self.server
	function server.HTTP_REQUEST_RECEIVED(serverSocket, clientSocket, request)
		print("HTTP_REQUEST_RECEIVED")

		assertEquals(request.method, "GET")
		assertEquals(request.requestedURL, "/chat")
		assertEquals(request.versionString, "HTTP/1.1")
		assertEquals(request.body, {})
		assertEquals(request.headers["Host"], "example.com:8000")
		assertEquals(request.headers["Upgrade"], "websocket")
		assertEquals(request.headers["Connection"], "Upgrade")
		assertEquals(request.headers["Sec-WebSocket-Key"], "dGhlIHNhbXBsZSBub25jZQ")
		assertEquals(request.headers["Sec-WebSocket-Version"], "13")

		hasServerReceivedMessage = true

		local response = {
			versionString = "HTTP/1.1",
			statusCode = 200,
			statusText = "OK",
			headers = {},
			body = "Hello world!",
		}
		serverSocket:SendHttpResponse(clientSocket, response)
	end

	function server.TCP_WRITE_SUCCEEDED()
		print("TCP_WRITE_SUCCEEDED")
		hasServerSentResponse = true
	end

	-- Hand off control to libuv to let async requests complete
	coroutine.yield()
end

function scenario:OnEvaluate()
	print("OnEvaluate")
	assertTrue(hasClientSentMessageToServer, "The client should have sent a message to the server")
	assertTrue(hasServerReceivedMessage, "The server should have received the client's message")
	assertTrue(hasServerSentResponse, "The server should have sent a response")
	assertTrue(hasClientReceivedEchoMessage, "The client should have received the response")
end

function scenario:OnCleanup()
	print("OnCleanup")
	self.client:Disconnect()
	self.server:StopListening()
end

return scenario
