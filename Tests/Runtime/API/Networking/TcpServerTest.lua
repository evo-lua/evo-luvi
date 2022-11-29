local TcpServer = {}

local uv = require("uv")

local currentThread = coroutine.running()

function TcpServer:Listen(port, host)
	DEBUG("Listening on " .. port .. ":" .. host)
	coroutine.yield()
end

TcpServer:Listen("localhost", 12345)

return TcpServer