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
		print("TCP_CONNECTION_ESTABLISHED")
		client:Send("Hello server!")
		hasClientSentMessageToServer = true
	end

	function client.TCP_CHUNK_RECEIVED(_, chunk)
		print("TCP_CHUNK_RECEIVED")
		assertEquals(chunk, "Hello server!", "Should receive the same message that was originally sent")
		hasClientReceivedEchoMessage = true
		-- The echo test is over, so we can continue with the report
		coroutine.resume(currentThread)
	end

	local server = self.server
	function server.TCP_CHUNK_RECEIVED(serverSocket, clientSocket, chunk)
		print("TCP_CHUNK_RECEIVED")
		assertEquals(chunk, "Hello server!")
		hasServerReceivedMessage = true
		serverSocket:Send(clientSocket, chunk)
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
