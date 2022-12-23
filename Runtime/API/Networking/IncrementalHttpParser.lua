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
	instance.callbackEventBuffer = string_buffer.new()
	-- We can't easily pass the actual LuaJIT SBuf type to C, so use a proxy type to represent the writable area of the buffer instead
	instance.state.data = ffi.new("luajit_stringbuffer_reference_t")

	setmetatable(instance, { __index = self })

	return instance
end

function IncrementalHttpParser:GetNumBufferedEvents()
	return #self.callbackEventBuffer / ffi_sizeof("llhttp_event_t")
end

-- TODO add tests that catch the pragma packing issue, add this to llhttp (for llhttp_event_t tests, C code)
local function llhttpEvent_ToString(event)
	local readableEventName = llhttp.FFI_EVENTS[tonumber(event.event_id)]
	local NO_PAYLOAD_STRING = "no payload"
	local READABLE_PAYLOAD_STRING =
		format("with payload: %s", ffi_string(event.payload_start_pointer, event.payload_length))

	local hasPayload = (tonumber(event.payload_length) > 0)
	local payloadString = hasPayload and READABLE_PAYLOAD_STRING or NO_PAYLOAD_STRING

	return bold(format("<llhttp-ffi event #%s (%s), %s>", tonumber(event.event_id), readableEventName, payloadString))
end


--TODO raise error event that can be used to DC client or send an error code if eventID is 0 (should never happen)
function IncrementalHttpParser:ReplayParserEvent(event)
	local eventID = event.event_id
	eventID = llhttp.FFI_EVENTS[eventID]

	self[eventID](self, eventID, event)
end

function IncrementalHttpParser:ClearBufferedEvents()
	self.callbackEventBuffer:reset()
end

-- ReplayRecordedCallbackEvents(callbackRecord)
function IncrementalHttpParser:ParseChunkAndRecordCallbackEvents(chunk)
	if chunk == "" then return end

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
	return tonumber(llhttp_get_errno(self.state)) == llhttp.ERROR_TYPES.HPE_OK
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

-- function IncrementalHttpParser:HTTP_EVENT_BUFFER_TOO_SMALL(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_MESSAGE_BEGIN(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_HEADER_FIELD(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADER_VALUE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADERS_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_URL_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_VERSION_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADER_FIELD_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADER_VALUE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_HEADER(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_RESET(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end

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
	self.bufferedMessage:Reset()
end

function IncrementalHttpParser:GetBufferedMessage()
	return self.bufferedMessage
end

return IncrementalHttpParser
