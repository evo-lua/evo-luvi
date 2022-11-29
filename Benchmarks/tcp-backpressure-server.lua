local uv = require("uv")
local function setInterval(interval, callback)
	local timer = uv.new_timer()
	timer:start(interval, interval, function ()
	  callback()
	end)
	return timer
  end

local TcpServer = C_Networking.TcpServer

local socketOptions = {
	port = 12345,
	hostName = "127.0.0.1",
}
local server = TcpServer(socketOptions)

function server.TCP_CHUNK_RECEIVED(clientSocket, chunk)
	-- NOOP
end

function server:TCP_SESSION_STARTED(clientSocket)
	DEBUG("TCP_SESSION_STARTED", self:GetClientInfo(clientSocket))

	local simulateBusySocket = false
	self:StopReading(clientSocket)

	setInterval(5000, function()
		if simulateBusySocket then
			TEST("Starting client reads to take away the backpressure")
			self:StartReading(clientSocket)
		else
			TEST("Stopping client reads to induce backpressure")
			self:StopReading(clientSocket)
		end
		simulateBusySocket = not simulateBusySocket

	end)
end