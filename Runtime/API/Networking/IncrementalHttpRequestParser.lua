local ffi = require("ffi")
local llhttp = require("llhttp")

local ffi_new = ffi.new
local ffi_string = ffi.string

local llhttp_init = llhttp.bindings.llhttp_init

local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_errno_name = llhttp.bindings.llhttp_errno_name
local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof

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
		currentRequest = HttpRequest(),
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

function IncrementalHttpRequestParser:GetCurrentRequest()
	return self.currentRequest
end

IncrementalHttpRequestParser.__call = IncrementalHttpRequestParser.Construct
setmetatable(IncrementalHttpRequestParser, IncrementalHttpRequestParser)

return IncrementalHttpRequestParser
