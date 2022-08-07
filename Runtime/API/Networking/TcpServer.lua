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
	print("TcpServer", target, key)
	if rawget(TcpServer, key) ~= nil then
		print("TcpServer")
		return TcpServer[key]
	end
	if TcpSocket[key] ~= nil then
		print("TcpSocket")
		return TcpSocket[key]
	end
	print("rawget")
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

		self.connections[client] = true
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
	local success, errorMessage = client:write(chunk, function()
		self:TCP_WRITE_SUCCEEDED(client, chunk)
	end)

	if not success then -- Likely: Write failed due to backpressure from the other end (i.e., the write queue is full)
		-- Since there's no buffer/drain mechanism currently, this is the best we can do
		self:TCP_WRITE_FAILED(client, errorMessage, chunk)
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

		-- EOF = client closed readable side; keeping the socket half-open seems pointless here, so just shut it down
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
	client:close(onCloseHandler)

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

function TcpServer:TCP_WRITE_SUCCEEDED(client, chunk)
	DEBUG("[TcpServer] TCP_WRITE_SUCCEEDED triggered", self:GetClientInfo(client), chunk)
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

return TcpServer
