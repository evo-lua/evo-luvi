-- @CONCERNS: Integration of native llhttp parser events with the Lua environment
local ffi = require("ffi")
local llhttp = require("llhttp")
local string_buffer = require("string.buffer")

local ffi_cast = ffi.cast
local ffi_sizeof = ffi.sizeof

local format = format

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

-- function IncrementalHttpParser:GetEventBuffer()
-- 	return self.eventBuffer
-- end

function IncrementalHttpParser:GetNumBufferedEvents()
	return #self.eventBuffer /  ffi_sizeof("llhttp_event_t")
end

local tonumber = tonumber
local table_insert = table.insert
local ffi_string = ffi.string
local bold = transform.bold

-- TODO add tests that catch the pragma packing issue
local function llhttpEvent_ToString(event)
	local readableEventName = llhttp.FFI_EVENTS[tonumber(event.event_id)]
	local NO_PAYLOAD_STRING = "no payload"
	local READABLE_PAYLOAD_STRING = format("with payload: %s", ffi_string(event.payload_start_pointer, event.payload_length))

	local hasPayload = (tonumber(event.payload_length) > 0)
	local payloadString = hasPayload and READABLE_PAYLOAD_STRING or NO_PAYLOAD_STRING

	return bold(format("<llhttp-ffi event #%s (%s), %s>", tonumber(event.event_id), readableEventName, payloadString))
end

function IncrementalHttpParser:GetBufferedEvents() -- TBD ProcessStoredEvents?
	local writeBuffer = ffi_cast("luajit_stringbuffer_reference_t*", self.state.data)

	local bufferedEvents = {}

	-- TODO better name...
	print("Dumping event buffer contents", self.eventBuffer)
	print("Events buffer contains " .. self:GetNumBufferedEvents() .. " entries (" .. #self.eventBuffer .. " bytes)")

	-- Avoids segfault (TODO remove?)
	if #self.eventBuffer == 0 then return {} end

	-- -- TODO pop all events, trigger Lua event handlers, reset buffer, handle error case (buffer too small)
	-- local events = ffi.cast("luajit_stringbuffer_reference_t*", self.state.data)
	local startPointer, lengthInBytes = self.eventBuffer:ref()
	-- local events = ffi_cast("llhttp_event_t**", startPointer)
	for offset = 0, lengthInBytes - 1, ffi_sizeof("llhttp_event_t") do
		local event = ffi_cast("llhttp_event_t*", startPointer + offset)
		-- print(offset, event, llhttpEvent_ToString(event))

		-- ExtractEventInfo(cdata) -- TODO test, move to llhttp?
		local eventID = tonumber(event.event_id)
		-- Copying this does add more overhead, but I think the ease-of-use is worth it for the most common use cases
		-- cdata can easily SEGFAULT the server if used incorrectly, and if needed it could easily be exposed later
		-- TODO benchmark overhead (perf/memory) for this vs. raw cdata?
		local luaEvent = {
			eventID = llhttp.FFI_EVENTS[eventID],
			payload = ffi_string(event.payload_start_pointer, event.payload_length)
		}
		table_insert(bufferedEvents, luaEvent)
	end

	return bufferedEvents
	-- TODO queue should be empty now...
end

function IncrementalHttpParser:ReplayParserEvent(event)
	DEBUG(format("Replaying stored event: %s", llhttpEvent_ToString(event)))

	local eventID = tonumber(event.event_id)
	eventID = llhttp.FFI_EVENTS[eventID]
	-- TODO tests
	if not eventID then error("Cannot replay unknown FFI event " .. llhttpEvent_ToString(event)) end

	self.eventBuffer:skip(ffi_sizeof("llhttp_event_t"))
	print("Num bytes left: " .. #self.eventBuffer) -- TODO remove

	local payload = {
		eventData = event,
		payloadStartPointer = event.payload_start_pointer,
		payloadLengthInBytes = event.payload_length,
	}
	self[eventID](self, eventID, payload)
-- TODO reset buffer?
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	DEBUG("ParseNextChunk", #chunk, chunk)

	-- printf("Buffer contents before parsing: %s", eventBuffer)
	local eventBuffer = self.eventBuffer
	local writeBuffer = ffi_cast("luajit_stringbuffer_reference_t*", self.state.data)

	-- GetMaxRequiredBufferSize(chunk)
	-- Absolutely worst case upper bound: One char is sent at a time, and all chars trigger an event (VERY defensive)
	-- This could probably be reduced to minimize overhead, but then chunks are limited by the OS's socket buffer size anyway...
		-- TODO improve worst-case estimate: we cannot get individual characters in a single chunk (and llhttp docs are wrong, the events only trigger the first time that the character was encountered and not every single time...)
	local maxBufferSizeToReserve = #chunk * ffi_sizeof("llhttp_event_t")
	DEBUG("Trying to reserve " .. maxBufferSizeToReserve .. " bytes in the FFI write buffer ... ")
	local ptr, len = eventBuffer:reserve(maxBufferSizeToReserve)


		--TODO raise error event that can be used to DC client or send an error code
	-- local ptr, len = eventBuffer:reserve(#chunk * ffi_sizeof("llhttp_event_t"))
	printf("Reserved %s bytes in buffer %s (requested: %s, total size: %s)", len, ptr, maxBufferSizeToReserve, #eventBuffer)

	-- ResetEventBuffer (also call self.eventBuffer:reset()?)
	-- This is only used internally by the llhttp-ffi layer to queue events in order, and then we can commit as many bytes to the buffer
	writeBuffer.size = len
	writeBuffer.ptr = ptr
	writeBuffer.used = 0

	llhttp_execute(self.state, chunk, #chunk)
		-- printf("llhttp used %d bytes of the available %d", writeBuffer.used, writeBuffer.size)
		if writeBuffer.used > 0 then
			DEBUG("Total event buffer capacity: " .. tonumber(writeBuffer.size) .. " bytes")
			DEBUG("Events triggered by last chunk used: " .. tonumber(writeBuffer.used) .. " bytes")
			-- If nothing needs to be written, this can cause segfaults?
			eventBuffer:commit(writeBuffer.used)
			-- print("buffer_commit OK")

			-- DEBUG("Dumping queued events ...")
			-- dump(self:GetBufferedEvents())
		end

end

function IncrementalHttpParser:AddBufferedEvent(event)
	self.eventBuffer:putcdata(event, ffi_sizeof("llhttp_event_t"))
end

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
			DEBUG(eventID .. " triggered", payload.eventData, payload.payloadStartPointer, payload.payloadLengthInBytes)
		end
	end

return IncrementalHttpParser