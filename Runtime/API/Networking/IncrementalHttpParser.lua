local llhttp = require("llhttp")
local bindings = llhttp.bindings

local ffi = require("ffi")

local ffi_new = ffi.new
local ffi_string = ffi.string
local format = format
local setmetatable = setmetatable
local tonumber = tonumber
local rawget = rawget
local table_concat = table.concat
local table_insert = table.insert

local IncrementalHttpParser = {
	-- Used to reset the state that we have to cache because llhttp doesn't save it
	defaultState = {
		requestURL = "(not set)",
		errorCode = "(none)",
		body = "(none)",
		status = "(none)",
		lastHeaderField = "(none)",
	},
}

-- SaveInternalState(key, value)
-- ResetInternalState
-- IsHttpRequest(state)
-- IsHttpResponse(state)

-- SetRequestMode
-- SetResponseMode
-- SetAutoDetectMode
-- ToRequest/ToResponse/ToHttpMessage

function IncrementalHttpParser:Construct()
	local parserState = ffi_new("llhttp_t")
	local settings = ffi_new("llhttp_settings_t")

	local instance = {
		state = parserState,
		settings = settings,
		additionalState = {
			requestURL = IncrementalHttpParser.defaultState.requestURL,
			errorCode = IncrementalHttpParser.defaultState.errorCode,
			body = IncrementalHttpParser.defaultState.body,
			status = IncrementalHttpParser.defaultState.status,
			lastHeaderField = IncrementalHttpParser.defaultState.lastHeaderField,
		},
		headers = {},
	}

	-- Possible return values 0, -1, HPE_PAUSED
	settings.on_message_begin = function(parserState)
		instance:OnMessageBegin()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	-- Possible return values 0, -1, HPE_USER
	settings.on_url = function(parserState, stringPointer, stringLengthInBytes)
		local parsedString = ffi_string(stringPointer, stringLengthInBytes)
		instance:OnURL(parsedString)
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_status = function(parserState, stringPointer, stringLengthInBytes)
		local parsedString = ffi_string(stringPointer, stringLengthInBytes)
		instance:OnStatus(parsedString)
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_header_field = function(parserState, stringPointer, stringLengthInBytes)
		local parsedString = ffi_string(stringPointer, stringLengthInBytes)
		instance:OnHeaderField(parsedString)
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_header_value = function(parserState, stringPointer, stringLengthInBytes)
		local parsedString = ffi_string(stringPointer, stringLengthInBytes)
		instance:OnHeaderValue(parsedString)
		return llhttp.ERROR_TYPES.HPE_OK
	end

	-- Possible return values:
	-- 0	- Proceed normally
	-- 1	- Assume that request/response has no body, and proceed to parsing the next message
	-- 2	- Assume absence of body (as above) and make `llhttp_execute()` return HPE_PAUSED_UPGRADE
	-- -1	- Error
	-- HPE_PAUSED`
	settings.on_headers_complete = function(parserState)
		instance:OnHeadersComplete()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	-- Possible return values 0, -1, HPE_USER
	settings.on_body = function(parserState, stringPointer, stringLengthInBytes)
		local parsedString = ffi_string(stringPointer, stringLengthInBytes)
		instance:OnBody(parsedString)
		return llhttp.ERROR_TYPES.HPE_OK
	end

	-- Possible return values 0, -1, HPE_PAUSED
	-- settings.on_message_complete = function(parserState)
	-- 	instance:OnMessageComplete()
	-- 	return llhttp.ERROR_TYPES.HPE_OK
	-- end

	-- When on_chunk_header is called, the current chunk length is stored in parser->content_length.
	-- Possible return values 0, -1, `HPE_PAUSED`
	settings.on_chunk_header = function(parserState)
		instance:OnChunkHeader()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_chunk_complete = function(parserState)
		instance:OnChunkComplete()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	-- Information-only callbacks, return value is ignored
	settings.on_url_complete = function(parserState)
		instance:OnUrlComplete()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_status_complete = function(parserState)
		instance:OnStatusComplete()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_header_field_complete = function(parserState)
		instance:OnHeaderValueComplete()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	settings.on_header_value_complete = function(parserState)
		instance:OnHeaderValueComplete()
		return llhttp.ERROR_TYPES.HPE_OK
	end

	bindings.llhttp_init(parserState, llhttp.PARSER_TYPES.HTTP_BOTH, settings)

	local inheritanceLookupMetatable = {
		__index = function(t, v)
			if IncrementalHttpParser[v] then
				return IncrementalHttpParser[v]
			else
				return rawget(t, v)
			end
		end,
		__tostring = function()
			local tokens = {}
			tokens[#tokens + 1] = "Message Type:\t" .. tonumber(instance.state.type)
			tokens[#tokens + 1] = "Method:\t\t" .. ffi_string(bindings.llhttp_method_name(instance.state.method))
			tokens[#tokens + 1] = "URL:\t\t" .. instance.additionalState.requestURL
			tokens[#tokens + 1] = "Version:\tHTTP/"
				.. tonumber(instance.state.http_major)
				.. "."
				.. tonumber(instance.state.http_minor)
			tokens[#tokens + 1] = "Status Code:\t" .. tonumber(instance.state.status_code)
			-- tokens[#tokens+1] = "Error Code:\t" .. tonumber(instance.state.errorCode)
			tokens[#tokens + 1] = "Error Code:\t" .. instance.additionalState.errorCode
			tokens[#tokens + 1] = "Body:\t\t" .. instance.additionalState.body
			tokens[#tokens + 1] = "Status:\t\t" .. instance.additionalState.status
			tokens[#tokens + 1] = "Last Header:\t" .. instance.additionalState.lastHeaderField
			-- tokens[#tokens+1] = "Content Length:\t" .. tonumber(instance.state.content_length)
			-- tokens[#tokens+1] = "AAAAAAAA:\t" .. tonumber(instance.state.type)

			tokens[#tokens + 1] = "Headers:\t" .. #instance.headers
			for key, value in pairs(instance.headers) do
				tokens[#tokens + 1] = "\t" .. key .. ": " .. value
			end

			local stringRepresentation = table_concat(tokens, "\n")
			return stringRepresentation
		end,
	}

	setmetatable(instance, inheritanceLookupMetatable)

	return instance
end

IncrementalHttpParser.__call = IncrementalHttpParser.Construct
setmetatable(IncrementalHttpParser, IncrementalHttpParser)

function IncrementalHttpParser:Reset()
	DEBUG("Resetting HTTP parser state")
	bindings.llhttp_finish(self.state) -- TBD what's the point of this?
	bindings.llhttp_reset(self.state)

	-- This state is only valid for the current request
	self.additionalState.requestURL = IncrementalHttpParser.defaultState.requestURL
	self.additionalState.errorCode = IncrementalHttpParser.defaultState.errorCode
	self.additionalState.body = IncrementalHttpParser.defaultState.body
	self.additionalState.status = IncrementalHttpParser.defaultState.status
	self.additionalState.lastHeaderField = IncrementalHttpParser.defaultState.lastHeaderField
	self.headers = {}
end

function IncrementalHttpParser:Execute(chunk)
	-- DEBUG("Executing parser on chunk", chunk)

	-- local errNo = bindings.llhttp_execute(self.state, chunk, #chunk)
	-- if tonumber(errNo) == llhttp.ERROR_TYPES.HPE_OK then
	-- 	return
	-- elseif tonumber(errNo) == llhttp.ERROR_TYPES.HPE_PAUSED_UPGRADE then
	-- 	DEBUG("Expecting upgrade")
	-- 	self:OnUpgrade()
	-- else
	-- 	local errorMessage = bindings.llhttp_errno_name(errNo)
	-- 	self:OnError(ffi_string(errorMessage))
	-- end
end

function IncrementalHttpParser:OnURL(requestedURL)
	DEBUG("OnURL", requestedURL)

	-- llhttp doesn't save this anywhere, so we must store the buffered string
	self.additionalState.requestURL = requestedURL
end

function IncrementalHttpParser:OnError(errorCode)
	DEBUG("OnError", errorCode)
	-- Would probably want to send 400 Bad Request response here?

	self.additionalState.errorCode = errorCode
end

function IncrementalHttpParser:OnMessageBegin()
	DEBUG("OnMessageBegin")
end

function IncrementalHttpParser:OnStatus(status)
	DEBUG("OnStatus", status)

	self.additionalState.status = status
end

function IncrementalHttpParser:OnHeaderField(fieldName)
	DEBUG("OnHeaderField", fieldName)

	-- todo multiples? needs tests, review spec/nodejs issue (I remember vaguely there was one)
	if self.headers[fieldName] then
		WARNING("Duplicate HTTP header key " .. fieldName)
	end
	self.headers[fieldName] = ""
	self.additionalState.lastHeaderField = fieldName
end

function IncrementalHttpParser:OnHeaderValue(fieldValue)
	DEBUG("OnHeaderValue", fieldValue)

	-- It's possible to receive multiple callbacks if field names or values are split into multiple buffers
	-- Because they're sent over TCP they arrive in order, so it should be safe to simply append them
	local fieldName = self.additionalState.lastHeaderField
	self.headers[fieldName] = self.headers[fieldName] .. fieldValue
end

function IncrementalHttpParser:OnHeadersComplete()
	DEBUG("OnHeadersComplete")
end

function IncrementalHttpParser:OnMessageComplete()
	DEBUG("OnMessageComplete")

	print(self)

	-- todo create request or response, depending on state/additionalstate, trigger OnRequest, OnResponse event
end

function IncrementalHttpParser:OnBody(body)
	DEBUG("OnBody", body)

	self.additionalState.body = body
end

function IncrementalHttpParser:OnChunkHeader()
	DEBUG("OnChunkHeader")
end

function IncrementalHttpParser:OnChunkComplete()
	DEBUG("OnChunkComplete")
end

function IncrementalHttpParser:OnUrlComplete()
	DEBUG("OnUrlComplete")
end

function IncrementalHttpParser:OnStatusComplete()
	DEBUG("OnStatusComplete")
end

function IncrementalHttpParser:OnHeaderFieldComplete()
	DEBUG("OnHeaderFieldComplete")
end

function IncrementalHttpParser:OnHeaderValueComplete()
	DEBUG("OnHeaderValueComplete")
end

function IncrementalHttpParser:OnUpgrade()
	DEBUG("OnUpgrade")
end

return IncrementalHttpParser
