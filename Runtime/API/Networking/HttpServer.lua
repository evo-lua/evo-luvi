local rawget = rawget
local setmetatable = setmetatable

local TcpSocket = require("TcpSocket")
local TcpServer = require("TcpServer")

local HttpServer = {}

function HttpServer.__index(target, key)
	print("HttpServer", target, key)
	if rawget(HttpServer, key) ~= nil then
		print("HttpServer")
		return HttpServer[key]
	end
	if TcpServer[key] ~= nil then
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

function HttpServer:Construct(creationOptions)
	local instance = TcpServer(creationOptions)
	setmetatable(instance, self)

	instance.httpParsers = {}

	dump(instance)
	return instance
end

HttpServer.__call = HttpServer.Construct
setmetatable(HttpServer, HttpServer)

local tonumber = tonumber

local llhttp = require("llhttp")
local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_errno_name = llhttp.bindings.llhttp_errno_name
local llhttp_init = llhttp.bindings.llhttp_init

local ffi = require("ffi")
local ffi_new = ffi.new
local ffi_string = ffi.string

function HttpServer:TCP_CLIENT_CONNECTED(client)
	DEBUG("[HttpServer] TCP_CLIENT_CONNECTED triggered", self:GetClientInfo(client))
	-- TODO create parser when client connects,
	local parserState = ffi_new("llhttp_t")
	local settings = ffi_new("llhttp_settings_t")
	-- TODO register callback
	-- TODO  hook into events

	llhttp_init(parserState, llhttp.PARSER_TYPES.HTTP_BOTH, settings)
	self.httpParsers[client] = parserState -- IncrementalHttpParser()
end

-- TODO call finish if client sends EOF

function HttpServer:TCP_CHUNK_RECEIVED(client, chunk)
	DEBUG("[HttpServer] TCP_CHUNK_RECEIVED triggered", self:GetClientInfo(client), chunk)

	local parser = self.httpParsers[client]

	DEBUG("Executing llhttp parser on chunk", chunk)

	local errNo = llhttp_execute(parser, chunk, #chunk)
	if tonumber(errNo) == llhttp.ERROR_TYPES.HPE_OK then
		return
	elseif tonumber(errNo) == llhttp.ERROR_TYPES.HPE_PAUSED_UPGRADE then
		DEBUG("Expecting HTTP upgrade")
		self:OnUpgradeRequestReceived(client)
	else
		local errorMessage = llhttp_errno_name(errNo) -- TODO append parser.reason ?
		self:OnParserError(client, ffi_string(errorMessage))
	end
end

function HttpServer:OnUpgradeRequestReceived(client)
	-- TODO
	DEBUG("[HttpServer] OnUpgradeRequestReceived triggered")
	-- HTTP_CONNECTION_UPGRADED
end

function HttpServer:OnParserError(client, errorMessage)
	DEBUG("[HttpServer] OnParserError triggered")
	self:TCP_CLIENT_READ_ERROR(client, errorMessage)

	-- TODO: Destroy parser, also on shutdown (Disconnect?) // TCP_CLIENT_DISCONNECTED

	self:Disconnect(client, errorMessage)
	self:TCP_SESSION_ENDED(client)
end

-- Customizable event handlers: These should be overwritten as needed
function HttpServer:HTTP_REQUEST_RECEIVED(client, request)
	DEBUG("[HttpServer] HTTP_REQUEST_RECEIVED triggered", self:GetClientInfo(client), request)
end

-- function HttpServer:HTTP_RESPONSE_SENT(client, response)
-- 	DEBUG("[HttpServer] HTTP_RESPONSE_SENT triggered", self:GetClientInfo(client), response)
-- end

function HttpServer:HTTP_CONNECTION_UPGRADED(client)
	DEBUG("[HttpServer] HTTP_CONNECTION_UPGRADED triggered", self:GetClientInfo(client))
end

return HttpServer
