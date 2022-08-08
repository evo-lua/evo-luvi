local tonumber = tonumber

local llhttp = require("llhttp")
local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_errno_name = llhttp.bindings.llhttp_errno_name
local llhttp_init = llhttp.bindings.llhttp_init
local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof

local ffi = require("ffi")
local ffi_new = ffi.new
local ffi_string = ffi.string

local rawget = rawget
local setmetatable = setmetatable

local TcpSocket = require("TcpSocket")
local TcpServer = require("TcpServer")
local IncrementalHttpRequestParser = require("IncrementalHttpRequestParser")

local HttpServer = {}

local function llhttpParserState__toHttpMessage(parser)
	-- struct llhttp__internal_s {
	-- 	int32_t _index;
	-- 	void* _span_pos0;
	-- 	void* _span_cb0;
	-- 	int32_t error;
	-- 	const char* reason;
	-- 	const char* error_pos;
	-- 	void* data;
	-- 	void* _current;
	-- 	uint64_t content_length;
	-- 	uint8_t type;
	-- 	uint8_t method;
	-- 	uint8_t http_major;
	-- 	uint8_t http_minor;
	-- 	uint8_t header_state;
	-- 	uint8_t lenient_flags;
	-- 	uint8_t upgrade;
	-- 	uint8_t finish;
	-- 	uint16_t flags;
	-- 	uint16_t status_code;
	-- 	void* settings;
	-- };
	local message = {
		error = tonumber(parser.error),
		reason = tostring(parser.reason),
		error_pos = tostring(parser.error_pos),
		content_length = tonumber(parser.content_length),
		type = tonumber(parser.type),
		method = tonumber(parser.method),
		http_major = tonumber(parser.http_major),
		http_minor = tonumber(parser.http_minor),
		header_state = tonumber(parser.header_state),
		lenient_flags = tonumber(parser.lenient_flags),
		upgrade = tonumber(parser.upgrade),
		finish = tonumber(parser.finish),
		flags = tonumber(parser.flags),
		status_code = tonumber(parser.status_code),
		data = tostring(parser.data),
	}
	return message
end

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

local pairs = pairs

function HttpServer:RegisterParserCallbacks(client)
	local parser = self.httpParsers[client]

	-- This is a bit convoluted, but llhttp doesn't offer any other way of registering events :/
	for callbackName, eventID in pairs(parser.INFO_CALLBACKS) do
		local function infoCallbackHandler(parserState)
			self[eventID](self, client)
			return llhttp.ERROR_TYPES.HPE_OK
		end
		parser.settings[callbackName] = infoCallbackHandler
	end

	for callbackName, eventID in pairs(parser.DATA_CALLBACKS) do
		local function dataCallbackHandler(parserState, stringPointer, stringLengthInBytes)
			local parsedString = ffi_string(stringPointer, stringLengthInBytes)
			self[eventID](self, client, parsedString)
			return llhttp.ERROR_TYPES.HPE_OK
		end
		parser.settings[callbackName] = dataCallbackHandler
	end
end

function HttpServer:InitializeRequestParser(client)
	local requestParser = IncrementalHttpRequestParser()
	self.httpParsers[client] = requestParser

	self:RegisterParserCallbacks(client)
end

function HttpServer:TCP_CLIENT_CONNECTED(client)
	DEBUG("[HttpServer] TCP_CLIENT_CONNECTED triggered", self:GetClientInfo(client))

	self:InitializeRequestParser(client)
end

-- TODO call finish if client sends EOF

function HttpServer:TCP_CHUNK_RECEIVED(client, chunk)
	DEBUG("[HttpServer] TCP_CHUNK_RECEIVED triggered", self:GetClientInfo(client), chunk)

	local parser = self.httpParsers[client] -- TODO

	DEBUG("Executing llhttp parser on chunk", chunk)

	local errNo = llhttp_execute(parser.state, chunk, #chunk) -- TODO Request mode
	if tonumber(errNo) == llhttp.ERROR_TYPES.HPE_OK then
		-- check if llhttp_message_needs_eof, then call finish?
		if llhttp_message_needs_eof(parser.state) then
			DEBUG("Message needs EOF")
		end
		-- llhttp_should_keep_alive?
		-- llhttp_finish -> invokes message completed cb
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
function HttpServer:HTTP_MESSAGE_RECEIVED(client, parser)
	-- TODO request, response, extract message
	DEBUG("[HttpServer] HTTP_MESSAGE_RECEIVED triggered", self:GetClientInfo(client), parser)
	local message = llhttpParserState__toHttpMessage(parser)
	dump(message)
end

function HttpServer:HTTP_REQUEST_RECEIVED(client, request)
	DEBUG("[HttpServer] HTTP_REQUEST_RECEIVED triggered", self:GetClientInfo(client), request)
end

function HttpServer:HTTP_CONNECTION_UPGRADED(client)
	DEBUG("[HttpServer] HTTP_CONNECTION_UPGRADED triggered", self:GetClientInfo(client))
end

-- TODO Move request parsing logic to the parser class

-- llhttp info callbacks
function HttpServer:HTTP_MESSAGE_BEGIN(client)
	DEBUG("[HttpServer] HTTP_MESSAGE_START triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_HEADERS_COMPLETE(client)
	DEBUG("[HttpServer] HTTP_HEADERS_COMPLETE triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_CHUNK_HEADER(client)
	DEBUG("[HttpServer] HTTP_CHUNK_HEADER triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_CHUNK_COMPLETE(client)
	DEBUG("[HttpServer] HTTP_CHUNK_COMPLETE triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_URL_COMPLETE(client)
	DEBUG("[HttpServer] HTTP_URL_COMPLETE triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_STATUS_COMPLETE(client)
	DEBUG("[HttpServer] HTTP_STATUS_COMPLETE triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_HEADER_FIELD_COMPLETE(client)
	DEBUG("[HttpServer] HTTP_HEADER_FIELD_COMPLETE triggered", self:GetClientInfo(client))
end
function HttpServer:HTTP_HEADER_VALUE_COMPLETE(client)
	DEBUG("[HttpServer] HTTP_HEADER_VALUE_COMPLETE triggered", self:GetClientInfo(client))
end

-- llhttp data callbacks
function HttpServer:HTTP_URL(client, parsedString)
	DEBUG("[HttpServer] HTTP_URL triggered", self:GetClientInfo(client), parsedString)
end
function HttpServer:HTTP_STATUS(client, parsedString)
	DEBUG("[HttpServer] HTTP_STATUS triggered", self:GetClientInfo(client), parsedString)
end
function HttpServer:HTTP_HEADER_FIELD(client, parsedString)
	DEBUG("[HttpServer] HTTP_HEADER_FIELD triggered", self:GetClientInfo(client), parsedString)
end
function HttpServer:HTTP_HEADER_VALUE(client, parsedString)
	DEBUG("[HttpServer] HTTP_HEADER_VALUE triggered", self:GetClientInfo(client), parsedString)
end
function HttpServer:HTTP_BODY(client, parsedString)
	DEBUG("[HttpServer] HTTP_BODY triggered", self:GetClientInfo(client), parsedString)
end

return HttpServer
