-- @CONCERNS: Integration of native llhttp parser events with the Lua environment
local ffi = require("ffi")
local llhttp = require("llhttp")
local string_buffer = require("string.buffer")

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
-- local llhttp_errno_name = llhttp.bindings.llhttp_errno_name
-- local llhttp_finish = llhttp.bindings.llhttp_finish
-- -- local llhttp_get_upgrade = llhttp.bindings.llhttp_get_upgrade -- NYI
-- local llhttp_message_needs_eof = llhttp.bindings.llhttp_message_needs_eof
-- local llhttp_method_name = llhttp.bindings.llhttp_method_name
-- local llhttp_reset = llhttp.bindings.llhttp_reset
-- local llhttp_should_keep_alive = llhttp.bindings.llhttp_should_keep_alive

local IncrementalHttpParser = {}

function IncrementalHttpParser:Construct()
	local instance = {
		state = ffi.new("llhttp_t"),
		settings = ffi.new("llhttp_settings_t"),
	}

	llhttp_settings_init(instance.settings)
	llhttp_init(instance.state, llhttp.PARSER_TYPES.HTTP_BOTH, instance.settings)

	-- The parser's userdata field here serves as an "event log" of sorts:
	-- To avoid C->Lua callbacks (which are extremely slow), buffer all events there... then replay them in Lua for fun and profit!
	-- This effectively trades CPU time for memory and should be "OK" for all common use cases (20-50x speedup vs. 24 extra bytes/event)
	instance.eventBuffer = string_buffer.new()
	-- We can't easily pass the actual LuaJIT SBuf type to C, so use a proxy type to represent the writable area of the buffer instead
	instance.state.data = ffi.new("luajit_stringbuffer_reference_t")

	setmetatable(instance, { __index = self })

	return instance
end

function IncrementalHttpParser:GetNumBufferedEvents()
	return #self.eventBuffer /  ffi_sizeof("llhttp_event_t")
end

-- TODO add tests that catch the pragma packing issue
local function llhttpEvent_ToString(event)
	local readableEventName = llhttp.FFI_EVENTS[tonumber(event.event_id)]
	local NO_PAYLOAD_STRING = "no payload"
	local READABLE_PAYLOAD_STRING = format("with payload: %s", ffi_string(event.payload_start_pointer, event.payload_length))

	local hasPayload = (tonumber(event.payload_length) > 0)
	local payloadString = hasPayload and READABLE_PAYLOAD_STRING or NO_PAYLOAD_STRING

	return bold(format("<llhttp-ffi event #%s (%s), %s>", tonumber(event.event_id), readableEventName, payloadString))
end

-- -- TODO pop all events, trigger Lua event handlers, reset buffer, handle error case (buffer too small)
-- TODO benchmark overhead (perf/memory) for this vs. raw cdata? If it's too much, add an option to only use raw cdata everywhere?
local table_new = require("table.new")
function IncrementalHttpParser:GetBufferedEvents()
	-- local bufferedEvents = table_new(self:GetNumBufferedEvents(), 0)

	local startPointer, lengthInBytes = self.eventBuffer:ref()
		-- local events = ffi_cast("llhttp_event_t[]", startPointer)
		-- print(events)
		-- for index = 0, self:GetNumBufferedEvents(), 1 do
		-- 	local event = events[index]
		-- 	print(index, event)
		-- end
	local events = table_new(self:GetNumBufferedEvents(), 0)

	local structSize = ffi_sizeof("llhttp_event_t")
	for offset = 0, lengthInBytes - 1, structSize do
		-- local event = ffi_cast("llhttp_event_t*", startPointer + offset)
	-- 	-- Copying this does add more overhead, but I think the ease-of-use is worth it (needs benchmarking)
	-- 	-- Raw cdata can easily SEGFAULT the server if used incorrectly, so exposing it in the high-level API seems a bit risky
	-- 	-- local luaEvent = self:CreateLuaEvent(event)
	-- 	bufferedEvents[offset / ffi_sizeof("llhttp_event_t")] = event
		-- table_insert(bufferedEvents, event)
		local event =  ffi_cast("llhttp_event_t*", startPointer + offset)
		-- table_insert(events, event)
		-- print(llhttpEvent_ToString(event))
	end



	return startPointer
end

function IncrementalHttpParser:CreateLuaEvent(event)
	local eventID = tonumber(event.event_id)
	local luaEvent = {
		eventID = llhttp.FFI_EVENTS[eventID],
		payload = ffi_string(event.payload_start_pointer, event.payload_length)
	}
	return luaEvent
end

--TODO raise error event that can be used to DC client or send an error code if eventID is 0 (should never happen)
function IncrementalHttpParser:ReplayParserEvent(event)
	-- DEBUG(format("Replaying stored event: %s", llhttpEvent_ToString(event)))

	local eventID = event.eventID
	-- eventID = llhttp.FFI_EVENTS[eventID]
	-- TODO tests
	-- if not eventID then error("Cannot replay unknown FFI event " .. llhttpEvent_ToString(event)) end

	-- self.eventBuffer:skip(ffi_sizeof("llhttp_event_t"))

	-- local payload = {
	-- 	-- eventData = event,
	-- 	payloadStartPointer = event.payload_start_pointer,
	-- 	payloadLengthInBytes = event.payload_length,
	-- }
	self[eventID](self, eventID, event.payload)
-- TODO reset buffer?
end

function IncrementalHttpParser:ClearBufferedEvents()
	self.eventBuffer:reset()
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	-- In order to process parser events in Lua (without relying on slow C->Lua callbacks), store them in an intermediary reusable buffer
	local eventBuffer = self.eventBuffer
	local maxBufferSizeToReserve = self:GetMaxRequiredBufferSize(chunk)

	local needsMoreSpace = #eventBuffer < maxBufferSizeToReserve
	local ptr, len
	if needsMoreSpace then
		ptr, len = eventBuffer:reserve(maxBufferSizeToReserve)
	else
		ptr, len = eventBuffer:ref()
	end

	-- This is only used internally by the llhttp-ffi layer to access the buffer, because we can't easily pass a raw LuaJIT SBuf* object
	local writableBufferArea = ffi_cast("luajit_stringbuffer_reference_t*", self.state.data)

	writableBufferArea.size = len
	writableBufferArea.ptr = ptr
	writableBufferArea.used = 0

	llhttp_execute(self.state, chunk, #chunk)

	if writableBufferArea.used > 0 then
		-- If nothing needs to be written, commits can cause segfaults
		eventBuffer:commit(writableBufferArea.used)
	end

end

function IncrementalHttpParser:GetMaxRequiredBufferSize(chunk)
	-- This is extremely wasteful due to the fact we cannot adjust the buffer size from C and have to reserve plenty of space ahead of time
	-- However, since the buffer is reused for each chunk and chunks are limited by the OS' RECV buffer (i.e., 4-16k max), it's acceptable?
	local upperBound = #chunk * ffi_sizeof("llhttp_event_t")
	return upperBound
end

function IncrementalHttpParser:AddBufferedEvent(event)
	self.eventBuffer:putcdata(event, ffi_sizeof("llhttp_event_t"))
end

-- TODO improve worst-case estimate: we cannot get individual characters in a single chunk (and llhttp docs are wrong, the events only trigger the first time that the character was encountered and not every single time...)
function IncrementalHttpParser:GetEventBufferSize()
	return #self.eventBuffer
end

-- TODO use this as default, as per event system RFC
-- function IncrementalHttpParser:OnEvent() end

-- function IncrementalHttpParser:HTTP_EVENT_BUFFER_TOO_SMALL(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_MESSAGE_BEGIN(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_URL(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_METHOD(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_VERSION(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_HEADER_FIELD(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADER_VALUE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADERS_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_BODY(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_MESSAGE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_URL_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_METHOD_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_VERSION_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADER_FIELD_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_HEADER_VALUE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_HEADER(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_CHUNK_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
-- function IncrementalHttpParser:HTTP_ON_RESET(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

local EventListenerMixin = require("EventListenerMixin")
mixin(IncrementalHttpParser, EventListenerMixin)

-- TBD: Do we want a default implementation that buffers the request in flight? If yes, this won't do...
	for index, readableEventName in pairs(llhttp.FFI_EVENTS) do
		IncrementalHttpParser[readableEventName] = function(parser, eventID, payload)
			DEBUG(eventID .. " triggered", payload)
		end
	end

return IncrementalHttpParser