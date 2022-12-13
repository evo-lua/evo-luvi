-- Creating a simple setInterval wrapper
local uv = require("uv")
local function setInterval(interval, callback)
	local timer = uv.new_timer()
	timer:start(interval, interval, function()
		callback()
	end)
	return timer
end

local scenario = C_Testing.Scenario("TCP client handles backpressure from server")
local TcpServer = C_Networking.TcpServer
local TcpClient = C_Networking.TcpClient

scenario:GIVEN("A TCP echo server is running on localhost")
scenario:WHEN("A client writes more data than the server can handle")
scenario:THEN("The client should trigger TCP_BACKPRESSURE_* events on backpressure status changes")

local TCP_BACKPRESSURE_DETECTED = false
local TCP_BACKPRESSURE_EASED = false

-- Cache this so it doesn't slow down the interval ticks more than necessary
local VERY_LARGE_STRING = string.rep("SPAM AND EGGS!", 1000, " ")

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

	function server.TCP_SESSION_STARTED(serverSocket, clientSocket)
		TEST("TCP_SESSION_STARTED triggered for TCP_BUSY_SERVER", serverSocket:GetClientInfo(clientSocket))
		TEST("TCP_BUSY_SERVER will stop reading from the client socket now")
		serverSocket:StopReading(clientSocket)

		-- Required to take off the backpressure after it was detected by the client
		server.stopPretendingToBeBusy = function()
			TEST("TCP_BUSY_SERVER will start reading from the client socket now")
			serverSocket:StartReading(clientSocket)
		end
	end

	-- Avoid cluttering the logs while spamming the server
	function client.TCP_WRITE_QUEUED() end
	function client.TCP_WRITE_SUCCEEDED() end

	function server.TCP_CHUNK_RECEIVED()
		-- Makes sure we can only get here after the client stops spamming us and we had time to catch up, and not before that
		assertTrue(TCP_BACKPRESSURE_DETECTED, "TCP_BUSY_SERVER should not receive any data since all reads were paused")
	end

	function client.TCP_BACKPRESSURE_DETECTED()
		TEST("TCP_BACKPRESSURE_DETECTED triggered for TCP_SPAM_CLIENT")
		TEST("TCP_SPAM_CLIENT is now stopping writes to counteract backpressure from the connected peer")

		TCP_BACKPRESSURE_DETECTED = true

		-- To allow the backpressure to subside, while still sending more data
		server.stopPretendingToBeBusy()
	end

	function client.TCP_BACKPRESSURE_EASED()
		TEST("TCP_BACKPRESSURE_EASED triggered for TCP_SPAM_CLIENT")
		TCP_BACKPRESSURE_EASED = true

		client:Disconnect()
		server:StopListening()

		-- The server has demonstrated it can keep up with the incoming data again, so no need to keep spamming it
		client.repeatingIntervalTimer:stop()

		coroutine.resume(currentThread)
	end

	function client.TCP_CONNECTION_ESTABLISHED(clientSocket)
		TEST("TCP_SPAM_CLIENT will now send ALL THE DATA to induce backpressure")
		client.repeatingIntervalTimer = setInterval(1, function()
			if not TCP_BACKPRESSURE_DETECTED then
				TEST("TCP_SPAM_CLIENT will send more data to induce backpressure")
				clientSocket:Send(VERY_LARGE_STRING)
			end
		end)
	end

	-- Hand off control to libuv to let async requests complete
	coroutine.yield()
end

function scenario:OnEvaluate()
	assertTrue(TCP_BACKPRESSURE_DETECTED, "The client should have triggered the TCP_BACKPRESSURE_DETECTED event")
	assertTrue(TCP_BACKPRESSURE_EASED, "The client should have triggered the TCP_BACKPRESSURE_EASED event")
end

return scenario
