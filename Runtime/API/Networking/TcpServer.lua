local uv = require("uv")

local rawget = rawget
local setmetatable = setmetatable
local table_count = table.count
local type = type

local TcpSocket = require("TcpSocket")

local DEFAULT_SERVER_CREATION_OPTIONS = {
	port = 12345,
	hostName = "127.0.0.1",
	-- These are the default values proposed by libuv (internally) as of 19/06/2022
	backlogQueueSize = 128,
}

local TcpServer = {
	port = DEFAULT_SERVER_CREATION_OPTIONS.port,
	hostName = DEFAULT_SERVER_CREATION_OPTIONS.hostName,
	backlogQueueSize = DEFAULT_SERVER_CREATION_OPTIONS.backlogQueueSize,
}

function TcpServer.__index(target, key)
	if rawget(TcpServer, key) ~= nil then
		return TcpServer[key]
	end
	if TcpSocket[key] ~= nil then
		return TcpSocket[key]
	end
	return rawget(target, key)
end

function TcpServer:Construct(creationOptions)
	creationOptions = creationOptions or DEFAULT_SERVER_CREATION_OPTIONS
	local instance = {
		handle = uv.new_tcp(),
		backlogQueueSize = creationOptions.backlogQueueSize or self.backlogQueueSize,
		hostName = creationOptions.hostName or self.hostName,
		port = creationOptions.port or self.port,
		connections = {},
	}

	setmetatable(instance, self)

	instance:StartListening()

	return instance
end

TcpServer.__call = TcpServer.Construct
setmetatable(TcpServer, TcpServer)

function TcpServer:StartListening()
	DEBUG(
		"Listening on tcp://"
			.. self.hostName
			.. ":"
			.. self.port
			.. " (Backlog queue size: "
			.. self.backlogQueueSize
			.. ")"
	)

	local function onIncomingConnectionCallback(errorMessage)
		if type(errorMessage) == "string" then
			return self:TCP_SOCKET_ERROR(errorMessage)
		end

		local client = uv.new_tcp()
		self:Accept(client)

		self.connections[client] = {
			backpressureUpperLimitInBytes = 1024 * 64,
			backpressureEasingLimitInBytes = 1024 * 8,
			isBackpressured = false,
		}
		self:TCP_CLIENT_CONNECTED(client)

		-- This is guaranteed [by libuv] to succeed when called for the first time
		self:StartReading(client)

		self:TCP_SESSION_STARTED(client)
	end

	local success, errorMessage = self:Bind(self.hostName, self.port)
	if not success then
		return self:TCP_SOCKET_ERROR(errorMessage)
	end

	success, errorMessage = self:Listen(self.backlogQueueSize, onIncomingConnectionCallback)
	if not success then
		return self:TCP_SOCKET_ERROR(errorMessage)
	end

	self:TCP_SERVER_STARTED()
end

function TcpServer:StopListening()
	DEBUG("Shutting down server at " .. self:GetURL())

	for client in pairs(self.connections) do
		self:Disconnect(client, "Server is shutting down")
		self:TCP_SESSION_ENDED(client)
	end

	self:Close()

	self:TCP_SERVER_STOPPED()
end

function TcpServer:Send(client, chunk)
	local connection = self.connections[client]

	local function onWriteCallback(errorMessage, ...)
		if type(errorMessage) == "string" then
			return self:TCP_SOCKET_ERROR(errorMessage)
		end

		if
			connection.isBackpressured
			and client:write_queue_size() <= (connection.backpressureEasingLimitInBytes or 0)
		then
			connection.isBackpressured = false
			self:TCP_BACKPRESSURE_EASED(client)
		end

		self:TCP_WRITE_SUCCEEDED(client, chunk)
	end

	local success, errorMessage = client:write(chunk, onWriteCallback)
	if not success then
		return self:TCP_WRITE_FAILED(client, errorMessage, chunk)
	end

	self:TCP_WRITE_QUEUED(client, chunk)

	if client:write_queue_size() > connection.backpressureUpperLimitInBytes then
		connection.isBackpressured = true
		self:TCP_BACKPRESSURE_DETECTED(client)
	end
end

function TcpServer:StopReading(client)
	client:read_stop()
end

function TcpServer:StartReading(client)
	client:read_start(function(errorMessage, chunk)
		if type(errorMessage) == "string" then
			return self:OnClientReadError(client, errorMessage)
		end

		if chunk then
			return self:TCP_CHUNK_RECEIVED(client, chunk)
		end

		-- When using a higher-level protocol, the registered parsers may need to finalize messages (e.g., HTTP/S)
		self:TCP_EOF_RECEIVED(client)
		self:Disconnect(client, "Client sent EOF")
		self:TCP_SESSION_ENDED(client)
	end)
end

function TcpServer:Disconnect(client, reason)
	reason = reason or "Unknown"

	DEBUG("Ending TCP session with client " .. self:GetClientInfo(client) .. " (Reason: " .. reason .. ")")

	local function onCloseHandler()
		self:TCP_CLIENT_DISCONNECTED(client, reason)
	end

	client:shutdown()
	if not client:is_closing() then
		client:close(onCloseHandler)
	end

	self.connections[client] = nil
end

function TcpServer:GetNumActiveSessions()
	return table_count(self.connections)
end

function TcpServer:GetMaxBacklogSize()
	return self.backlogQueueSize
end

function TcpServer:GetPeerName(client)
	return client:getpeername()
end

function TcpServer:GetClientInfo(handle)
	local peerAddressInfo = handle:getpeername()

	if not peerAddressInfo then
		return transform.bold("<" .. "Socket destroyed or not yet initialized" .. ">")
	end

	local socketID = peerAddressInfo.family .. "://" .. peerAddressInfo.ip .. ":" .. peerAddressInfo.port

	return transform.bold("<" .. socketID .. ">"), peerAddressInfo
end

function TcpServer:OnClientReadError(client, errorID)
	local humanReadableErrorMessage = uv.strerror(errorID)

	self:TCP_CLIENT_READ_ERROR(client, humanReadableErrorMessage)

	self:Disconnect(client, humanReadableErrorMessage)
	self:TCP_SESSION_ENDED(client)
end

-- Customizable event handlers: These should be overwritten as needed
function TcpServer:TCP_CLIENT_CONNECTED(client)
	DEBUG("[TcpServer] TCP_CLIENT_CONNECTED triggered", self:GetClientInfo(client))
end

function TcpServer:TCP_SOCKET_ERROR(errorMessage)
	DEBUG("[TcpServer] TCP_SOCKET_ERROR triggered", errorMessage)
end

function TcpServer:TCP_SESSION_STARTED(client)
	DEBUG("[TcpServer] TCP_SESSION_STARTED triggered", self:GetClientInfo(client))
end

function TcpServer:TCP_SESSION_ENDED(client)
	DEBUG("[TcpServer] TCP_SESSION_ENDED triggered", self:GetClientInfo(client))
end

function TcpServer:TCP_CHUNK_RECEIVED(client, chunk)
	DEBUG("[TcpServer] TCP_CHUNK_RECEIVED triggered", self:GetClientInfo(client), chunk)
end

function TcpServer:TCP_EOF_RECEIVED(client)
	DEBUG("[TcpServer] TCP_EOF_RECEIVED triggered", self:GetClientInfo(client))
end

function TcpServer:TCP_WRITE_SUCCEEDED(client, chunk)
	DEBUG("[TcpServer] TCP_WRITE_SUCCEEDED triggered", self:GetClientInfo(client), chunk)
end

function TcpServer:TCP_WRITE_QUEUED(client, chunk)
	DEBUG("[TcpServer] TCP_WRITE_QUEUED triggered", self:GetClientInfo(client), chunk)
end

function TcpServer:TCP_WRITE_FAILED(client, errorMessage, chunk)
	DEBUG("[TcpServer] TCP_WRITE_FAILED triggered", client, errorMessage, chunk)
end

function TcpServer:TCP_SERVER_STARTED()
	DEBUG("[TcpServer] TCP_SERVER_STARTED triggered")
end

function TcpServer:TCP_SERVER_STOPPED()
	DEBUG("[TcpServer] TCP_SERVER_STOPPED triggered")
end

function TcpServer:TCP_CLIENT_DISCONNECTED(client, reason)
	DEBUG("[TcpServer] TCP_CLIENT_DISCONNECTED triggered", self:GetClientInfo(client), reason)
end

function TcpServer:TCP_CLIENT_READ_ERROR(client, errorMessage)
	DEBUG("[TcpServer] TCP_CLIENT_READ_ERROR triggered", client, errorMessage)
end

function TcpServer:TCP_BACKPRESSURE_DETECTED(client)
	DEBUG("[TcpServer] TCP_BACKPRESSURE_DETECTED triggered", self:GetClientInfo(client), client:GetWriteQueueSize())
end
function TcpServer:TCP_BACKPRESSURE_EASED(client)
	DEBUG("[TcpServer] TCP_BACKPRESSURE_EASED triggered", self:GetClientInfo(client), client:GetWriteQueueSize())
end

return TcpServer
