-- Creating a simple setInterval wrapper
local uv = require("uv")
local function setInterval(interval, callback)
	local timer = uv.new_timer()
	timer:start(interval, interval, function ()
	  callback()
	end)
	return timer
  end


local scenario = C_Testing.Scenario("TCP server handles backpressure")

local TcpServer = C_Networking.TcpServer
local TcpClient = C_Networking.TcpClient

scenario:GIVEN("A TCP echo server is listening on localhost")
scenario:WHEN("A TCP client sends more data to the server than it can read")
scenario:THEN("The server should stop reading from the client's socket")

function scenario:OnSetup()
	local socketOptions = {
		port = 12345,
		hostName = "127.0.0.1",
	}
	self.server = TcpServer(socketOptions)
	self.client = TcpClient(socketOptions.hostName, socketOptions.port)
end

function scenario:OnRun()
	local server = self.server
	local client = self.client
	function server.TCP_SESSION_STARTED(serverSocket, clientSocket)
		-- print(collectgarbage("count"))
		TEST("Stopping client reads to simulate a slow peer")
		serverSocket:StopReading(clientSocket)
	end

	function server.TCP_CHUNK_RECEIVED(serverSocket, chunk)
		-- No-op since we don't actually need to do any processing here
			print("[Server] Receive buffer size in bytes: " .. serverSocket:GetReceiveBufferSize())
	end

	function client.TCP_CONNECTION_ESTABLISHED(tcpClient)
		TEST("Sending ALL THE DATA to induce backpressure")
		-- print(collectgarbage("count"))
		-- serverSocket:Send(string.rep("SPAM AND EGGS!", 100000, " "))
		-- local c = 0
		-- repeat
			-- tcpClient:Send(string.rep("SPAM AND EGGS!", 1, " "))

			setInterval(1, function()
				for i=0, 10000 do
					tcpClient:Send("SPAM AND EGGS! ")
				end
				print("Write queue size in bytes: " .. tcpClient:GetWriteQueueSize())
			end)

			-- if c % 10000 == 0 then
				-- print("Write queue size in bytes: " .. tcpClient:GetWriteQueueSize())
			-- end

			-- tbd write queue (stream) vs send buffer (handle)?

			-- c = c + 1
		-- until c < 0 -- todo until queue has >  35928320

	end

	-- function client:TCP_WRITE_SUCCEEDED()
		-- print(collectgarbage("count"))
	-- end

	coroutine.yield()
end

function scenario:OnEvaluate()
	assertFalse(true)
end

function scenario:OnCleanup()
	self.client:Disconnect()
	self.server:StopListening()
end

return scenario