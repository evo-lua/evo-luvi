-- TODO use LuaJIT string buffers (benchmark)
local ffi = require("ffi")
local llhttp = require("llhttp")

local ffi_new = ffi.new
local ffi_string = ffi.string

local llhttp_init = llhttp.bindings.llhttp_init
local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_errno_name = llhttp.bindings.llhttp_errno_name
local llhttp_finish = llhttp.bindings.llhttp_finish
-- local llhttp_get_upgrade = llhttp.bindings.llhttp_get_upgrade -- NYI
local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof
local llhttp_reset = llhttp.bindings.llhttp_reset
local llhttp_should_keep_alive = llhttp.bindings.llhttp_should_keep_alive

local IncrementalHttpRequestParser = {
	-- Signature: parserState : llhttp_t (the other arguments are useless)
	INFO_CALLBACKS = {
		on_message_begin = "HTTP_MESSAGE_BEGIN",
		on_headers_complete = "HTTP_HEADERS_COMPLETE",
		on_chunk_header = "HTTP_CHUNK_HEADER",
		on_chunk_complete = "HTTP_CHUNK_COMPLETE",
		on_url_complete = "HTTP_URL_COMPLETE",
		on_status_complete = "HTTP_STATUS_COMPLETE",
		on_header_field_complete = "HTTP_HEADER_FIELD_COMPLETE",
		on_header_value_complete = "HTTP_HEADER_VALUE_COMPLETE",
		on_message_complete = "HTTP_MESSAGE_COMPLETE",
	},
	-- Signature: parserState : llhttp_t, stringPointer, stringLengthInBytes
	DATA_CALLBACKS = {
		on_url = "HTTP_URL",
		on_status = "HTTP_STATUS",
		on_header_field = "HTTP_HEADER_FIELD",
		on_header_value = "HTTP_HEADER_VALUE",
		on_body = "HTTP_BODY",
	},
}

local HttpRequest = require("HttpRequest")

function IncrementalHttpRequestParser:Construct()
	local instance = {
		state = ffi_new("llhttp_t"),
		settings = ffi_new("llhttp_settings_t"),
		bufferedRequest = HttpRequest(),
		isBufferReady = false,
		lastReceivedHeaderKey = "",
		lastReceivedHeaderValue = "",
	}

	llhttp_init(instance.state, llhttp.PARSER_TYPES.HTTP_REQUEST, instance.settings)

	setmetatable(instance, self)

	return instance
end

local rawget = rawget

function IncrementalHttpRequestParser.__index(target, key)
	if rawget(IncrementalHttpRequestParser, key) ~= nil then
		return IncrementalHttpRequestParser[key]
	end
	return rawget(target, key)
end

function IncrementalHttpRequestParser:GetBufferedRequest()
	if not self.isBufferReady then
		return
	end

	return self.bufferedRequest
end

local tonumber = tonumber

function IncrementalHttpRequestParser:RegisterParserCallbacks()
	-- This is a bit convoluted, but llhttp doesn't offer any other way of registering events :/
	for callbackName, eventID in pairs(self.INFO_CALLBACKS) do
		local function infoCallbackHandler(parserState)
			self[eventID](self)
			return llhttp.ERROR_TYPES.HPE_OK
		end
		self.settings[callbackName] = infoCallbackHandler
	end

	for callbackName, eventID in pairs(self.DATA_CALLBACKS) do
		local function dataCallbackHandler(parserState, stringPointer, stringLengthInBytes)
			local parsedString = ffi_string(stringPointer, stringLengthInBytes)
			self[eventID](self, parsedString)
			return llhttp.ERROR_TYPES.HPE_OK
		end
		self.settings[callbackName] = dataCallbackHandler
	end
end

function IncrementalHttpRequestParser:ParseNextChunk(chunk)
	local errNo = llhttp_execute(self.state, chunk, #chunk)
	local isParserInErrorState = tonumber(errNo) == llhttp.ERROR_TYPES.HPE_OK
	if isParserInErrorState then
		if llhttp_message_needs_eof(self.state) then
			DEBUG("Message needs EOF")
		end

		if llhttp_should_keep_alive(self.state) then
			DEBUG("Expecting another message; connection should be kept alive")
		end
	end

	if tonumber(errNo) == llhttp.ERROR_TYPES.HPE_PAUSED_UPGRADE then
		DEBUG("Expecting HTTP upgrade")
	end

	local errorMessage = llhttp_errno_name(errNo)
	return isParserInErrorState, ffi_string(errorMessage)
end

function IncrementalHttpRequestParser:IsExpectingUpgrade()
	-- Should use llhttp_get_upgrade instead (not currently exported)
	return tonumber(self.state.upgrade) == 1
end

function IncrementalHttpRequestParser:IsExpectingEndOfTransmission()
	return tonumber(llhttp_message_needs_eof(self.state)) == 1
end

function IncrementalHttpRequestParser:FinalizeBufferedRequest()
	DEBUG("[IncrementalHttpRequestParser] Finalizing buffered request")
	local errNo = llhttp_finish(self.state)
	local isParserInErrorState = tonumber(errNo) == llhttp.ERROR_TYPES.HPE_OK

	local errorMessage = llhttp_errno_name(errNo)
	return isParserInErrorState, ffi_string(errorMessage)
end

function IncrementalHttpRequestParser:ResetInternalState()
	DEBUG("Resetting internal parser state")
	llhttp_reset(self.state)
	self.bufferedRequest = HttpRequest()
	self.lastReceivedHeaderKey = ""
	self.lastReceivedHeaderValue = ""
end

IncrementalHttpRequestParser.__call = IncrementalHttpRequestParser.Construct
setmetatable(IncrementalHttpRequestParser, IncrementalHttpRequestParser)

-- llhttp info callbacks
function IncrementalHttpRequestParser:HTTP_MESSAGE_BEGIN()
	DEBUG("[IncrementalHttpRequestParser] HTTP_MESSAGE_BEGIN triggered")
end
function IncrementalHttpRequestParser:HTTP_HEADERS_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_HEADERS_COMPLETE triggered")
end
function IncrementalHttpRequestParser:HTTP_CHUNK_HEADER()
	DEBUG("[IncrementalHttpRequestParser] HTTP_CHUNK_HEADER triggered")
end
function IncrementalHttpRequestParser:HTTP_CHUNK_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_CHUNK_COMPLETE triggered")
end
function IncrementalHttpRequestParser:HTTP_URL_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_URL_COMPLETE triggered")
end
function IncrementalHttpRequestParser:HTTP_STATUS_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_STATUS_COMPLETE triggered")
end
function IncrementalHttpRequestParser:HTTP_HEADER_FIELD_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_HEADER_FIELD_COMPLETE triggered")
end
function IncrementalHttpRequestParser:HTTP_HEADER_VALUE_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_HEADER_VALUE_COMPLETE triggered")

	local fieldName = self.lastReceivedHeaderKey
	local fieldValue = self.lastReceivedHeaderValue
	DEBUG(format("Storing received header pair - %s: %s", fieldName, fieldValue))
	self.bufferedRequest.headers[fieldName] = fieldValue

	-- This is somewhat redundant, but allows serializing headers in the exact order they were received later
	-- .All the while, also preserving the ability to perform dictionary lookups (constant-time + ease-of-use)
	self.bufferedRequest.headers[#self.bufferedRequest.headers + 1] = fieldName

	-- Reset buffer so the next key-value-pair can be stored
	self.lastReceivedHeaderKey = ""
	self.lastReceivedHeaderValue = ""
end

-- TODO check for missing upvalues everywhere

function IncrementalHttpRequestParser:HTTP_MESSAGE_COMPLETE()
	DEBUG("[IncrementalHttpRequestParser] HTTP_MESSAGE_COMPLETE triggered")
	self.isBufferReady = true

	local methodID = tonumber(self.state.method)
	local methodName = llhttp.HTTP_METHODS[methodID]
	self.bufferedRequest.method = methodName

	local major = self.state.http_major
	local minor = self.state.http_minor
	self.bufferedRequest.versionString = format("HTTP/%d.%d", major, minor)
end

-- llhttp data callbacks
function IncrementalHttpRequestParser:HTTP_URL(parsedString)
	DEBUG("[IncrementalHttpRequestParser] HTTP_URL triggered", parsedString)
	self.bufferedRequest.requestedURL = self.bufferedRequest.requestedURL .. parsedString
end

function IncrementalHttpRequestParser:HTTP_STATUS(parsedString)
	DEBUG("[IncrementalHttpRequestParser] HTTP_STATUS triggered", parsedString)
	self.bufferedRequest.requestedURL = self.bufferedRequest.requestedURL .. parsedString
end
function IncrementalHttpRequestParser:HTTP_HEADER_FIELD(parsedString)
	DEBUG("[IncrementalHttpRequestParser] HTTP_HEADER_FIELD triggered", parsedString)

	-- -- todo multiples? needs tests, review spec/nodejs issue (I remember vaguely there was one)
	-- if self.headers[fieldName] then
	-- 	WARNING("Duplicate HTTP header key " .. fieldName)
	-- end
	-- self.headers[fieldName] = ""
	-- self.additionalState.lastHeaderField = fieldName

	self.lastReceivedHeaderKey = self.lastReceivedHeaderKey .. parsedString
end
function IncrementalHttpRequestParser:HTTP_HEADER_VALUE(parsedString)
	DEBUG("[IncrementalHttpRequestParser] HTTP_HEADER_VALUE triggered", parsedString)

	self.lastReceivedHeaderValue = self.lastReceivedHeaderValue .. parsedString
end

function IncrementalHttpRequestParser:HTTP_BODY(parsedString)
	DEBUG("[IncrementalHttpRequestParser] HTTP_BODY triggered", parsedString)
	self.bufferedRequest.body = self.bufferedRequest.body .. parsedString
end

return IncrementalHttpRequestParser
