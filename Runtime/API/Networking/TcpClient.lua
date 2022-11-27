local rawget = rawget
local setmetatable = setmetatable
local type = type

local TcpSocket = require("TcpSocket")

local TcpClient = {}

function TcpClient.__index(target, key)
	if rawget(TcpClient, key) ~= nil then
		return TcpClient[key]
	end
	if TcpSocket[key] ~= nil then
		return TcpSocket[key]
	end
	return rawget(target, key)
end

function TcpClient:Construct(hostName, port)
	local instance = TcpSocket(hostName, port)

	setmetatable(instance, self)

	instance:StartConnecting(hostName, port)

	return instance
end

TcpClient.__call = TcpClient.Construct
setmetatable(TcpClient, TcpClient)

function TcpClient:StartConnecting()
	DEBUG("Connecting to tcp://" .. self.hostName .. ":" .. self.port)

	local function onIncomingDataCallback(errorMessage, chunk)
		if type(errorMessage) == "string" then
			return self:TCP_SOCKET_ERROR(errorMessage)
		end

		if chunk then
			return self:TCP_CHUNK_RECEIVED(chunk)
		end

		-- Received EOF, i.e., peer sent FIN to signal they're going away
		self:TCP_SESSION_ENDED()
	end

	local function onConnectionEstablishedCallback(errorMessage, ...)
		if type(errorMessage) == "string" then
			return self:TCP_SOCKET_ERROR(errorMessage)
		end

		self:TCP_CONNECTION_ESTABLISHED()

		-- This is guaranteed [by libuv] to succeed when called for the first time
		self:StartReading(onIncomingDataCallback)

		self:TCP_SESSION_STARTED()
	end

	self:Connect(self.hostName, self.port, onConnectionEstablishedCallback)
end

function TcpClient:Disconnect()
	if self:IsClosing() then
		return
	end

	local function onCloseHandler()
		self:TCP_SOCKET_CLOSED()
	end

	self:StopReading()
	self:Shutdown() -- Don't use callbacks for the writable end's shutdown; it's largely useless and will be confusing to some
	self:Close(onCloseHandler)
end

function TcpClient:Send(chunk)
	local function onWriteCallback(errorMessage, ...)
		if type(errorMessage) == "string" then
			return self:TCP_SOCKET_ERROR(errorMessage)
		end

		self:TCP_WRITE_SUCCEEDED(chunk)
	end

	local success, errorMessage = self:Write(chunk, onWriteCallback)
	if not success then -- Likely: Write failed due to backpressure from the other end (i.e., the write queue is full)
		-- Since there's no buffer/drain mechanism currently, this is the best we can do
		self:TCP_WRITE_FAILED(errorMessage, chunk)
	end
end

function TcpClient:OnSocketError(errorMessage)
	self:TCP_SOCKET_ERROR(errorMessage)

	if errorMessage ~= "ECANCELED" then
		-- If cancelled, the handle was already closed by libuv and this will error
		self:Disconnect()
	end
end

-- Customizable event handlers: These should be overwritten as needed
function TcpClient:TCP_SOCKET_ERROR(errorMessage)
	DEBUG("[TcpClient] TCP_SOCKET_ERROR triggered")
end

function TcpClient:TCP_CONNECTION_ESTABLISHED()
	DEBUG("[TcpClient] TCP_CONNECTION_ESTABLISHED triggered")
end
function TcpClient:TCP_SESSION_STARTED()
	DEBUG("[TcpClient] TCP_SESSION_STARTED triggered")
end
function TcpClient:TCP_WRITE_SUCCEEDED(chunk)
	DEBUG("[TcpClient] TCP_WRITE_SUCCEEDED triggered", chunk)
end
function TcpClient:TCP_WRITE_FAILED(errorMessage, chunk)
	DEBUG("[TcpClient] TCP_WRITE_FAILED triggered", errorMessage, chunk)
end
function TcpClient:TCP_CHUNK_RECEIVED(chunk)
	DEBUG("[TcpClient] TCP_CHUNK_RECEIVED triggered", chunk)
end
function TcpClient:TCP_SESSION_ENDED()
	DEBUG("[TcpClient] TCP_SESSION_ENDED triggered")
end
function TcpClient:TCP_SOCKET_CLOSED()
	DEBUG("[TcpClient] TCP_SOCKET_CLOSED triggered")
end

return TcpClient
