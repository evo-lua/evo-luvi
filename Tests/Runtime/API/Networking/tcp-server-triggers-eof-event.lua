local scenario = C_Testing.Scenario("TCP server triggers TCP_EOF_RECEIVED")
local TcpServer = C_Networking.TcpServer
local TcpClient = C_Networking.TcpClient

scenario:GIVEN("A TCP echo server is running on localhost")
scenario:WHEN("A client closes the readable side of the connection")
scenario:THEN("The server should trigger the TCP_EOF_RECEIVED event")

local hasTriggeredEvent = false

function scenario:OnSetup()
	local options = {
		port = 54321,
		hostName = "127.0.0.1",
	}
	self.server = TcpServer(options)
	self.client = TcpClient(options.hostName, options.port)
end

function scenario:OnRun()
	local currentThread = coroutine.running()

	local server = self.server
	local client = self.client

	function server.TCP_EOF_RECEIVED()
		hasTriggeredEvent = true
		server:StopListening()
		coroutine.resume(currentThread)
	end

	function client.TCP_SESSION_STARTED()
		client:Disconnect()
	end

	-- Hand off control to libuv to let async requests complete
	coroutine.yield()
end

function scenario:OnEvaluate()
	assertTrue(hasTriggeredEvent, "The server should have triggered the TCP_EOF_RECEIVED event")
end

return scenario
