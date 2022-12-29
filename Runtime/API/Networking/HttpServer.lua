local rawget = rawget
local setmetatable = setmetatable

local TcpSocket = require("TcpSocket")
local TcpServer = require("TcpServer")
local IncrementalHttpParser = require("IncrementalHttpParser")

local HttpServer = {}

function HttpServer.__index(target, key)
	if rawget(HttpServer, key) ~= nil then
		return HttpServer[key]
	end
	if TcpServer[key] ~= nil then
		return TcpServer[key]
	end
	if TcpSocket[key] ~= nil then
		return TcpSocket[key]
	end
	return rawget(target, key)
end

function HttpServer:Construct(creationOptions)
	local instance = TcpServer(creationOptions)
	setmetatable(instance, self)

	instance.httpParsers = {}

	return instance
end

HttpServer.__call = HttpServer.Construct
setmetatable(HttpServer, HttpServer)

function HttpServer:InitializeRequestParser(client)
	local requestParser = IncrementalHttpParser()
	self.httpParsers[client] = requestParser
end

function HttpServer:TCP_CLIENT_CONNECTED(client)
	DEBUG("[HttpServer] TCP_CLIENT_CONNECTED triggered", self:GetClientInfo(client))

	self:InitializeRequestParser(client)
end

function HttpServer:TCP_CHUNK_RECEIVED(client, chunk)
	DEBUG("[HttpServer] TCP_CHUNK_RECEIVED triggered", self:GetClientInfo(client), chunk)

	local parser = self.httpParsers[client]
	local wasParserExpectingUpgrade = parser:IsExpectingUpgrade()
	local wasParserExpectingEOF = parser:IsExpectingEOF()

	if wasParserExpectingUpgrade then
		-- Upgraded protocol handlers should override this event listener and take care of incoming chunks instead
		ERROR("HTTP connection should be upgraded, but currently isn't (no protocol handler registered?)")
		-- In the meantime, sever connection to ensure no unexpected behavior occurs
		self:OnParserError(client, "Awaiting upgrade, but received more bytes (Needs protocol handler?)")
		return
	end

	if wasParserExpectingEOF then
		-- This shouldn't happen unless keep-alive is set (not yet supported)
		ERROR("Awaiting EOF from client, but received more bytes")
		-- In the meantime, sever connection to ensure no unexpected behavior occurs
		self:OnParserError(client, "Awaiting EOF, but received additional bytes (Unsupported keep-alive request?)")
		return
	end

	DEBUG("Executing low-level HTTP parser on incoming chunk", chunk)
	local isOK, errorMessage = parser:ParseNextChunk(chunk)

	if parser:IsExpectingUpgrade() and not wasParserExpectingUpgrade then
		self:OnUpgradeRequestReceived(client)
	else
		if not isOK then
			self:OnParserError(client, errorMessage)
			return
		end
	end

	if parser:IsExpectingEOF() and not wasParserExpectingEOF then
		DEBUG("Received end of request, waiting for EOF now")
		return
	end

	local request = parser:GetBufferedRequest()
	if not request then -- Not yet complete
		return
	end

	self:HTTP_REQUEST_RECEIVED(client, request)
	parser:ResetInternalState() -- Prepare for new requests, if the parser is to be re-used (keep-alive enabled)
end

function HttpServer:OnUpgradeRequestReceived(client)
	-- TODO
	DEBUG("[HttpServer] OnUpgradeRequestReceived triggered")
	-- Protocol handlers should be initialized here if supported (HTTPS/WS/WSS), then replace the TCP_CHUNK_RECEIVED handler
	-- Afterwards, trigger new event to signal successful upgrade: HTTP_CONNECTION_UPGRADED(eventID, protocol)
	-- Where protocol is one of { "ws", "https", "wss" }
end

function HttpServer:OnParserError(client, errorMessage)
	DEBUG("[HttpServer] OnParserError triggered")
	self:TCP_CLIENT_READ_ERROR(client, errorMessage)

	-- TODO: Destroy parser, also on shutdown (Disconnect?) // TCP_CLIENT_DISCONNECTED

	self:Disconnect(client, errorMessage)
	self:TCP_SESSION_ENDED(client)
end

function HttpServer:TCP_EOF_RECEIVED(client)
	DEBUG("[HttpServer] TCP_EOF_RECEIVED triggered", self:GetClientInfo(client))
	local parser = self.httpParsers[client]
	local isParserExpectingEOF = parser:IsExpectingEOF()

	if not isParserExpectingEOF then
		WARNING("Received EOF in the middle of an ongoing HTTP request (connection failed or misbehaving client?)")
		-- This seems like an incomplete request, so just sever the connection to avoid unexpected errors
		self:OnParserError(client, "Unexpected EOF received in the middle of an ongoing request")
		return
	end

	-- local isOK, errorMessage = parser:FinalizeBufferedRequest()
	-- if not isOK then
	-- 	self:OnParserError(client, errorMessage)
	-- 	return
	-- end

	local request = parser:GetBufferedRequest()
	self:HTTP_REQUEST_RECEIVED(client, request)
end

function HttpServer:SendHttpResponse(client, responseObject)
	-- TODO NYI
	local responseString = responseObject:ToString()
	DEBUG(format("Sending response of length %d to client %s", #responseString, self:GetClientInfo(client)))

	self:Send(client, responseString)
end

function HttpServer:HTTP_REQUEST_RECEIVED(client, request)
	DEBUG("[HttpServer] HTTP_REQUEST_RECEIVED triggered", self:GetClientInfo(client), request)
end

function HttpServer:HTTP_CONNECTION_UPGRADED(client)
	DEBUG("[HttpServer] HTTP_CONNECTION_UPGRADED triggered", self:GetClientInfo(client))
end

return HttpServer
