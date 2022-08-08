local ffi = require("ffi")
local llhttp = require("llhttp")

local ffi_new = ffi.new
local ffi_string = ffi.string

local llhttp_init = llhttp.bindings.llhttp_init

local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_errno_name = llhttp.bindings.llhttp_errno_name
local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof
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
		cachedRequest = HttpRequest(),
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

function IncrementalHttpRequestParser:GetCachedRequest()
	return self.cachedRequest
end

local tonumber = tonumber

function IncrementalHttpRequestParser:ParseNextChunk(chunk)

	local errNo = llhttp_execute(self.state, chunk, #chunk)
	if tonumber(errNo) == llhttp.ERROR_TYPES.HPE_OK then
		if llhttp_message_needs_eof(self.state) then
			DEBUG("Message needs EOF")
		end

		if llhttp_should_keep_alive(self.state) then
			DEBUG("Expecting another message; connection should be kept alive")
		end


		return true
	end

	if tonumber(errNo) == llhttp.ERROR_TYPES.HPE_PAUSED_UPGRADE then
		DEBUG("Expecting HTTP upgrade")
	end

		-- TODO append parser.reason ?
	local errorMessage = llhttp_errno_name(errNo)
	return nil, ffi_string(errorMessage)
end

function IncrementalHttpRequestParser:ResetInternalState()
	-- TODO
end

IncrementalHttpRequestParser.__call = IncrementalHttpRequestParser.Construct
setmetatable(IncrementalHttpRequestParser, IncrementalHttpRequestParser)

return IncrementalHttpRequestParser
