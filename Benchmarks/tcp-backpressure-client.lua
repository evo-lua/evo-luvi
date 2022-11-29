-- Creating a simple setInterval wrapper
local uv = require("uv")
local function setInterval(interval, callback)
	local timer = uv.new_timer()
	timer:start(interval, interval, function ()
	  callback()
	end)
	return timer
  end

local TcpClient = C_Networking.TcpClient
local socketOptions = {
	port = 12345,
	hostName = "127.0.0.1",
}
local client = TcpClient(socketOptions.hostName, socketOptions.port)

function client.TCP_WRITE_SUCCEEDED() end
function client.TCP_WRITE_QUEUED() end

local shouldStopSending = false

function client:TCP_BACKPRESSURE_DETECTED()
	DEBUG("TCP_BACKPRESSURE_DETECTED", self:GetWriteQueueSize())
	TEST("Stopping writes to counteract backpressure from the connected peer")
	shouldStopSending = true
end

function client.TCP_CONNECTION_ESTABLISHED(tcpClient)
	TEST("Sending ALL THE DATA to induce backpressure")

	setInterval(1, function()
		-- while true do


			if not shouldStopSending then
				if tcpClient:GetWriteQueueSize() > 0 then print("Write queue size in bytes: " .. tcpClient:GetWriteQueueSize()) end

				tcpClient:Send(string.rep("SPAM AND EGGS!", 1000, " "))
			elseif tcpClient:GetWriteQueueSize() == 0 then
				-- TODO should use TCP_BACKPRESSURE_EASED event?
				TEST("Continue with writes since the backpressure has eased")
				shouldStopSending = false
			end

		-- end
	end)

end