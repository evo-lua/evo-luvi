local ffi = require("ffi")
local llhttp = require("llhttp")
local string_buffer = require("string.buffer")

local HttpMessage = require("HttpMessage")

local ffi_cast = ffi.cast
local ffi_sizeof = ffi.sizeof
local ffi_string = ffi.string

local format = format
local tonumber = tonumber
local table_insert = table.insert
local bold = transform.bold

local llhttp_init = llhttp.bindings.llhttp_init
local llhttp_settings_init = llhttp.bindings.llhttp_settings_init
local llhttp_execute = llhttp.bindings.llhttp_execute
local llhttp_get_errno = llhttp.bindings.llhttp_get_errno
local llhttp_should_keep_alive = llhttp.bindings.llhttp_should_keep_alive
local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof
local llhttp_get_upgrade = llhttp.bindings.llhttp_get_upgrade
local llhttp_get_error_reason = llhttp.bindings.llhttp_get_error_reason

local llhttp_userdata_allocate_buffer = llhttp.llhttp_userdata_allocate_buffer
local llhttp_userdata_get_message = llhttp.llhttp_userdata_get_message

local IncrementalHttpParser = {}

function IncrementalHttpParser:Construct()
	local instance = {
		state = ffi.new("llhttp_t"),
		settings = ffi.new("llhttp_settings_t"),
		bufferedMessage = HttpMessage(),
	}

	llhttp_settings_init(instance.settings)
	llhttp_init(instance.state, llhttp.PARSER_TYPES.HTTP_BOTH, instance.settings)

	-- The parser's userdata field here serves as an "event log" of sorts:
	-- To avoid C->Lua callbacks (which are extremely slow), buffer all events there... then replay them in Lua for fun and profit!
	-- This effectively trades CPU time for memory and should be "OK" for all common use cases (20-50x speedup vs. 17 extra bytes/event)
	-- instance.callbackEventBuffer = string_buffer.new()
	-- We can't easily pass the actual LuaJIT SBuf type to C, so use a proxy type to represent the writable area of the buffer instead
	-- local userdataBuffer = llhttp_userdata_allocate_buffer()
	-- instance.state.data = ffi_cast("llhttp_userdata_t*", userdataBuffer) -- This is safe because llhttp stores header + reference first
	-- instance.userdataBuffer = userdataBuffer
	instance.http_message = ffi.new("http_message_t") -- Anchor so it doesn't accidentally get GC'ed and SEGFAULTS the runtime...
	instance.state.data = instance.http_message
	-- instance.state.data = ffi.new("http_message_t")

	setmetatable(instance, { __index = self })

	return instance
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	llhttp_execute(self.state, chunk, #chunk)

	local userdata = ffi_cast("http_message_t*", self.state.data)
	-- self.userdataBuffer:commit(userdata.buffer.used)

	if self.extendedPayloadBuffer then
		self.extendedPayloadBuffer:commit(self.http_message.extended_payload_buffer.used)
		-- TODO reinit buffer so it can be used again?
	end

	return userdata

	-- return llhttp_userdata_get_message(self.userdataBuffer)
end

function IncrementalHttpParser:ParseChunkAndRecordCallbackEvents(chunk)
	if chunk == "" then
		return
	end

	-- To trigger parser events in Lua (without relying on slow C->Lua callbacks), we can store them in a buffer while we're in C land
	local callbackEventBuffer = self.callbackEventBuffer
	local maxBufferSizeToReserve = self:GetMaxRequiredBufferSize(chunk)

	local needsMoreSpace = #callbackEventBuffer < maxBufferSizeToReserve
	local ptr, len
	if needsMoreSpace then
		ptr, len = callbackEventBuffer:reserve(maxBufferSizeToReserve)
	else
		ptr, len = callbackEventBuffer:ref()
	end

	-- This is only used internally by the llhttp-ffi layer to access the buffer, because we can't easily pass a raw LuaJIT SBuf* object
	local writableBufferArea = ffi_cast("luajit_stringbuffer_reference_t*", self.state.data)

	writableBufferArea.size = len
	writableBufferArea.ptr = ptr
	writableBufferArea.used = 0

	llhttp_execute(self.state, chunk, #chunk) -- The FFI layer "magically" saves the events it encounters in the llhttp userdata here

	-- If nothing needs to be written, commits can cause segfaults
	if writableBufferArea.used == 0 then
		return
	end
	callbackEventBuffer:commit(writableBufferArea.used)

	return callbackEventBuffer
end

function IncrementalHttpParser:GetMaxRequiredBufferSize(chunk)
	-- This is extremely wasteful due to the fact we cannot adjust the buffer size from C and have to reserve plenty of space ahead of time
	-- However, since the buffer is reused for each chunk and chunks are limited by the OS' RECV buffer (i.e., 4-16k max), it's acceptable?
	local upperBound = #chunk * ffi_sizeof("llhttp_event_t")
	return upperBound
end

function IncrementalHttpParser:AddBufferedEvent(event)
	self.callbackEventBuffer:putcdata(event, ffi_sizeof("llhttp_event_t"))
end

-- TODO improve worst-case estimate: we cannot get individual characters in a single chunk (and llhttp docs are wrong, the events only trigger the first time that the character was encountered and not every single time...)
function IncrementalHttpParser:GetEventBufferSize()
	return #self.callbackEventBuffer
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

function IncrementalHttpParser:IsMessageComplete()
	-- TODO?
end

function IncrementalHttpParser:GetLastError()
	local cdata = llhttp_get_error_reason(self.state)

	if cdata == nil then
		return
	end -- Cannot convert NULL pointer to Lua string (obviously)

	return ffi_string(cdata)
end

-- TODO tests
function IncrementalHttpParser:EnableExtendedPayloadBuffer(expectedPayloadSizeInBytes)
	local message = self.http_message
	local stringBuffer, referencePointer, numReservedBytes = llhttp.allocate_extended_payload_buffer(message)
	self.extendedPayloadBuffer = stringBuffer
	message.extended_payload_buffer.ptr = referencePointer
	message.extended_payload_buffer.size = numReservedBytes
	message.extended_payload_buffer.used = 0
end

function IncrementalHttpParser:GetExtendedPayload()
	return tostring(self.extendedPayloadBuffer)
end

-- TODO use llhttp methods to get major, minor, method, status code, upgrade flag without copying stuff in event handlers (benchmark impact)

-- TODO use this as default, as per event system RFC
-- function IncrementalHttpParser:OnEvent(event)

-- end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

local EventListenerMixin = require("EventListenerMixin")
mixin(IncrementalHttpParser, EventListenerMixin)

-- TBD: Do we want a default implementation that buffers the request in flight? If yes, this won't do...
for index, readableEventName in pairs(llhttp.FFI_EVENTS) do
	IncrementalHttpParser[readableEventName] = function(parser, eventID, payload)
		-- TEST("EVENT", eventID, payload)
	end
end

function IncrementalHttpParser:HTTP_EVENT_BUFFER_TOO_SMALL(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_MESSAGE_BEGIN(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_HEADER_FIELD(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_HEADER_VALUE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_HEADERS_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_URL_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_STATUS_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_VERSION_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_HEADER_FIELD_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_HEADER_VALUE_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_CHUNK_HEADER(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_CHUNK_COMPLETE(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--   payload.payload_length)
end
function IncrementalHttpParser:HTTP_ON_RESET(eventID, payload)
	-- DEBUG(eventID .. " triggered", payload.payload_start_pointer,
	--       payload.payload_length)
end

-- TODO DRY

function IncrementalHttpParser:HTTP_ON_METHOD(eventID, payload)
	-- TEST(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length)
	self.bufferedMessage.method:putcdata(payload.payload_start_pointer, payload.payload_length)
end

function IncrementalHttpParser:HTTP_ON_VERSION(eventID, payload)
	-- TEST(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length)
	self.bufferedMessage.httpVersion:putcdata(payload.payload_start_pointer, payload.payload_length)
end

function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload)
	-- TEST(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length)
	self.bufferedMessage.statusCode:putcdata(payload.payload_start_pointer, payload.payload_length)
end

function IncrementalHttpParser:HTTP_ON_BODY(eventID, payload)
	-- TEST(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length)
	self.bufferedMessage.body:putcdata(payload.payload_start_pointer, payload.payload_length)
end

function IncrementalHttpParser:HTTP_ON_URL(eventID, payload)
	-- TEST(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length)
	self.bufferedMessage.requestTarget:putcdata(payload.payload_start_pointer, payload.payload_length)
end

function IncrementalHttpParser:HTTP_ON_MESSAGE_COMPLETE(eventID, payload)
	-- TEST(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length)
	-- print(self.bufferedMessage:ToString())
	-- dump(self.bufferedMessage)
	-- print(self.bufferedMessage:ToString())
	self.bufferedMessage:Reset()
end

function IncrementalHttpParser:GetBufferedMessage()
	return self.bufferedMessage
end

return IncrementalHttpParser
