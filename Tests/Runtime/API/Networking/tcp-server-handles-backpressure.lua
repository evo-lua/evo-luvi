-- Creating a simple setInterval wrapper
local uv = require("uv")
local function setInterval(interval, callback)
	local timer = uv.new_timer()
	timer:start(interval, interval, function()
		callback()
	end)
	return timer
end

local scenario = C_Testing.Scenario("TCP server handles backpressure from client")
local TcpServer = C_Networking.TcpServer
local TcpClient = C_Networking.TcpClient

scenario:GIVEN("A TCP echo server is running on localhost")
scenario:WHEN("The server writes more data than a client can handle")
scenario:THEN("The server should trigger TCP_BACKPRESSURE_* events on backpressure status changes")

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

	function client.TCP_SESSION_STARTED(clientSocket)
		TEST("TCP_SESSION_STARTED triggered for TCP_BUSY_CLIENT")
		TEST("TCP_BUSY_CLIENT will stop reading from the client socket now")
		clientSocket:StopReading()

		-- Required to take off the backpressure after it was detected by the client
		client.stopPretendingToBeBusy = function()
			TEST("TCP_BUSY_CLIENT will start reading from the server socket now")
			clientSocket:StartReading()
		end
	end

	-- Avoid cluttering the logs while spamming the server
	function server.TCP_WRITE_QUEUED() end
	function server.TCP_WRITE_SUCCEEDED() end

	function client.TCP_CHUNK_RECEIVED()
		-- Makes sure we can only get here after the server stops spamming us and we had time to catch up, and not before that
		assertTrue(TCP_BACKPRESSURE_DETECTED, "TCP_BUSY_CLIENT should not receive any data since all reads were paused")
	end

	function server.TCP_BACKPRESSURE_DETECTED()
		TEST("TCP_BACKPRESSURE_DETECTED triggered for TCP_SPAM_SERVER")
		TEST("TCP_SPAM_SERVER is now stopping writes to counteract backpressure from the connected peer")

		TCP_BACKPRESSURE_DETECTED = true

		-- To allow the backpressure to subside, while still sending more data
		client.stopPretendingToBeBusy()
	end

	function server.TCP_BACKPRESSURE_EASED()
		TEST("TCP_BACKPRESSURE_EASED triggered for TCP_SPAM_SERVER")
		TCP_BACKPRESSURE_EASED = true

		client:Disconnect()
		server:StopListening()

		-- The client has demonstrated it can keep up with the incoming data again, so no need to keep spamming it
		server.repeatingIntervalTimer:stop()

		coroutine.resume(currentThread)
	end

	function server.TCP_SESSION_STARTED(serverSocket, clientSocket)
		TEST("TCP_SPAM_SERVER will now send ALL THE DATA to induce backpressure")
		server.repeatingIntervalTimer = setInterval(1, function()
			if not TCP_BACKPRESSURE_DETECTED then
				TEST("TCP_SPAM_SERVER will send more data to induce backpressure")
				server:Send(clientSocket, VERY_LARGE_STRING)
			end
		end)
	end

	-- Hand off control to libuv to let async requests complete
	coroutine.yield()
end

function scenario:OnEvaluate()
	assertTrue(TCP_BACKPRESSURE_DETECTED, "The server should have triggered the TCP_BACKPRESSURE_DETECTED event")
	assertTrue(TCP_BACKPRESSURE_EASED, "The server should have triggered the TCP_BACKPRESSURE_EASED event")
end

return scenario
