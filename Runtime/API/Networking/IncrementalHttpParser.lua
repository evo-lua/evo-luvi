local ffi = require("ffi")
local llhttp = require("llhttp")

local ffi_cast = ffi.cast
local ffi_string = ffi.string

local tonumber = tonumber

local llhttp_init = llhttp.bindings.llhttp_init
local llhttp_settings_init = llhttp.bindings.llhttp_settings_init
local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_get_errno = llhttp.bindings.llhttp_get_errno
local llhttp_should_keep_alive = llhttp.bindings.llhttp_should_keep_alive
local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof
local llhttp_get_upgrade = llhttp.bindings.llhttp_get_upgrade
local llhttp_get_error_reason = llhttp.bindings.llhttp_get_error_reason

local IncrementalHttpParser = {}

function IncrementalHttpParser:Construct()
	local instance = {
		state = ffi.new("llhttp_t"),
		settings = ffi.new("llhttp_settings_t"),
	}

	llhttp_settings_init(instance.settings)
	llhttp_init(instance.state, llhttp.PARSER_TYPES.HTTP_BOTH, instance.settings)

	-- Anchor the cdata objects so they don't accidentally get collected and SEGFAULT the runtime
	instance.http_message = ffi.new("http_message_t")
	instance.state.data = instance.http_message

	setmetatable(instance, { __index = self })

	return instance
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	llhttp_execute(self.state, chunk, #chunk)

	if self.extendedPayloadBuffer then
		self.extendedPayloadBuffer:commit(self.http_message.extended_payload_buffer.used)
	end

	return ffi_cast("http_message_t*", self.state.data)
end

function IncrementalHttpParser:IsOK()
	local llhttpErrorCode = tonumber(llhttp_get_errno(self.state))
	local isValidMessage = (llhttpErrorCode == llhttp.ERROR_TYPES.HPE_OK)
	local isUpgradeRequest = (llhttpErrorCode == llhttp.ERROR_TYPES.HPE_PAUSED_UPGRADE) -- Not really an error...
	return isValidMessage or isUpgradeRequest
end

function IncrementalHttpParser:IsExpectingUpgrade()
	return tonumber(llhttp_get_upgrade(self.state)) == 1
end

function IncrementalHttpParser:IsExpectingEOF()
	return tonumber(llhttp_message_needs_eof(self.state)) == 1
end

function IncrementalHttpParser:ShouldKeepConnectionAlive()
	return tonumber(llhttp_should_keep_alive(self.state)) == 1
end

function IncrementalHttpParser:GetLastError()
	local cdata = llhttp_get_error_reason(self.state)

	if cdata == nil then -- Cannot convert NULL pointer to Lua string
		return
	end

	return ffi_string(cdata)
end

function IncrementalHttpParser:EnableExtendedPayloadBuffer(expectedPayloadSizeInBytes)
	local message = self.http_message

	local referencePointer, numReservedBytes
	if self.extendedPayloadBuffer then -- No need to allocate another buffer since it can just be re-used
		self.extendedPayloadBuffer:reset()
		referencePointer, numReservedBytes =
			self.extendedPayloadBuffer:reserve(llhttp.DEFAULT_EXTENDED_PAYLOAD_BUFFER_SIZE_IN_BYTES)
		message.extended_payload_buffer.ptr = referencePointer
		message.extended_payload_buffer.size = numReservedBytes
	else
		self.extendedPayloadBuffer = llhttp.allocate_extended_payload_buffer(message)
	end

	message.extended_payload_buffer.used = 0
end

function IncrementalHttpParser:GetExtendedPayload()
	return tostring(self.extendedPayloadBuffer)
end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

return IncrementalHttpParser
