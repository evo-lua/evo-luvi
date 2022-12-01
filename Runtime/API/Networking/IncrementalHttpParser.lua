local ffi = require("ffi")
local llhttp = require("llhttp")

local string_buffer = require("string.buffer")

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

	llhttp_settings_init(instance.settings) -- Also sets up callbacks in C (to avoid Lua/C call overhead)
	llhttp_init(instance.state, llhttp.PARSER_TYPES.HTTP_BOTH, instance.settings)

	-- The parser's userdata field serves as an "event log" of sorts:
	-- To avoid C->Lua callbacks (which are extremely slow), buffer all events there... then replay them in Lua for fun and profit!
	-- This effectively trades CPU time for memory and should be "OK" for all common use cases (20-50x speedup vs. 24 extra bytes/event)
	instance.eventBuffer = string_buffer.new()
	-- We can't easily pass the actual LuaJIT SBuf type to C, so use a proxy type for the writable area of the buffer instead
	instance.state.data = ffi.new("luajit_stringbuffer_reference_t")

	setmetatable(instance, { __index = self })

	return instance
end

local ffi_cast = ffi.cast
local ffi_sizeof = ffi.sizeof

function IncrementalHttpParser:GetEventBuffer()
	return self.eventBuffer
end

function IncrementalHttpParser:GetNumBufferedEvents()
	return #self.eventBuffer /  ffi_sizeof("llhttp_event_t")
end

local tonumber = tonumber

function IncrementalHttpParser:GetBufferedEvents()
	local writeBuffer = ffi_cast("luajit_stringbuffer_reference_t*", self.state.data)

	-- TODO better name...
	print("Dumping write buffer contents", self.eventBuffer)
	print("Write buffer contains " .. self:GetNumBufferedEvents() .. " entries (" .. #self.eventBuffer .. " bytes)")

	if #self.eventBuffer == 0 then return {} end -- Avoids segfault (TODO remove?)

	-- -- TODO pop all events, trigger Lua event handlers, reset buffer, handle error case (buffer too small)
	while #self.eventBuffer > 0 do
		local event = ffi.cast("llhttp_event_t*", self.eventBuffer)
		-- print()
		print("Stored event:", event)
		local eventID = tonumber(event.event_id)
		printf("\tevent_id: %d", eventID)
		eventID = llhttp.FFI_EVENTS[eventID] or "UNKNOWN_FFI_EVENT"
		print("FFI Event: " .. eventID)
		printf("\tpayload_start_pointer: %s", event.payload_start_pointer)
		printf("\tpayload_length: %d", tonumber(event.payload_length))
		-- print()
		print("Popping event...")
		self.eventBuffer:skip(ffi_sizeof("llhttp_event_t"))
		print("Num bytes left: " .. #self.eventBuffer)


		-- ReplayNativeEvent(eventID)
		DEBUG("Replaying FFI event " .. tostring(eventID))
		if not self[eventID] then
			ERROR("Failed to trigger FFI event " .. tostring(eventID))
		else
			-- TBD Do we really want this? It's wasteful, better to just pass at/length and append to a buffered request's string buffer!
			local payload = {
				-- TODO remove
				payloadStartPointer = event.payload_start_pointer,
				payloadEnd = event.payload_length,
			}
			self[eventID](self, eventID, payload)
		end
	end

	-- TODO queue should be empty now...
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	DEBUG("ParseNextChunk", #chunk, chunk)

	-- printf("Buffer contents before parsing: %s", eventBuffer)
	local eventBuffer = self.eventBuffer
	local writeBuffer = ffi_cast("luajit_stringbuffer_reference_t*", self.state.data)

	-- Absolutely worst case upper bound: One char is sent at a time, and all chars trigger an event (VERY defensive)
	-- This could probably be reduced to minimize overhead, but then chunks are limited by the OS's socket buffer size anyway...
	local maxBufferSizeToReserve = #chunk * ffi_sizeof("llhttp_event_t")
	DEBUG("Trying to reserve " .. maxBufferSizeToReserve .. " bytes in the FFI write buffer ... ")
	local ptr, len = eventBuffer:reserve(maxBufferSizeToReserve)


		--TODO raise error event that can be used to DC client or send an error code
	-- local ptr, len = eventBuffer:reserve(#chunk * ffi_sizeof("llhttp_event_t"))
	printf("Reserved %s bytes in buffer %s (requested: %s, total size: %s)", len, ptr, maxBufferSizeToReserve, #eventBuffer)

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

			DEBUG("Dumping queued events ...")
			dump(self:GetBufferedEvents())

			-- eventBuffer:reset()
			-- print("buffer_reset OK", c)
		end

	-- local firstEvent = ffi.cast("llhttp_event_t*", eventBuffer)
	-- -- TODO pop all events, trigger Lua event handlers, reset buffer, handle error case (buffer too small)
	-- print()
	-- print("First stored event:", firstEvent)
	-- printf("\tevent_id: %d", tonumber(firstEvent.event_id))
	-- printf("\tpayload_start_pointer: %s", firstEvent.payload_start_pointer)
	-- printf("\tpayload_length: %d", tonumber(firstEvent.payload_length))
	-- print()



	-- printf("Buffer contents after parsing: %s", tostring(eventBuffer))
	-- eventBuffer:reset()
end

-- TODO use this as default, as per event system RFC
function IncrementalHttpParser:OnEvent() end

function IncrementalHttpParser:HTTP_EVENT_BUFFER_TOO_SMALL(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_MESSAGE_BEGIN(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_URL(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_METHOD(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_VERSION(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_HEADER_FIELD(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_HEADER_VALUE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_HEADERS_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_BODY(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_MESSAGE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_URL_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_STATUS_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_METHOD_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_VERSION_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_HEADER_FIELD_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_STATUS(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_HEADER_VALUE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_NAME_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_CHUNK_EXTENSION_VALUE_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_CHUNK_HEADER(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_CHUNK_COMPLETE(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end
function IncrementalHttpParser:HTTP_ON_RESET(eventID, payload) DEBUG(eventID .. " triggered", payload.payload_start_pointer, payload.payload_length) end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

return IncrementalHttpParser