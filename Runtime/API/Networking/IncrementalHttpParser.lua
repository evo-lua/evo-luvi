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

	-- The parser's userdata field can be used as a event log to avoid C->Lua callbacks (extremely slow)
	-- Setting up the buffer from Lua is much simpler since we don't need to deal with the Lua state directly here
	instance.eventBuffer = string_buffer.new()
	-- instance.state.data = instance.eventLogBuffer:ref() -- Can only store void pointer, which we will cast in C to SBuf* before using it
	-- instance.state.data = instance.eventLogBuffer -- Can only store void pointer, which we will cast in C to SBuf* before using it

	-- We can't easily pass the actual LuaJIT type to C here, so use a proxy type for the writable area of the buffer instead
	instance.state.data = ffi.new("lj_writebuffer_t")

	setmetatable(instance, { __index = self })

	return instance
end

local ffi_cast = ffi.cast
local ffi_sizeof = ffi.sizeof

function IncrementalHttpParser:GetEventBuffer()
	return self.eventBuffer
end

function IncrementalHttpParser:GetNumBufferedEvents()
	return (#self.eventBuffer / 1) -- TODO sizeof event_t
end

function IncrementalHttpParser:GetBufferedEvents()
	local writeBuffer = ffi_cast("lj_writebuffer_t*", self.state.data)
	print("Dumping write buffer contents",#self.eventBuffer) -- TODO better name...

	if #self.eventBuffer == 0 then return {} end -- Avoids segfault

	for index = 0, #self.eventBuffer do
		print("Fetching event " .. index)
		local event = ffi_cast("llhttp_event_t*", self.eventBuffer)
		print("Event " .. index .. ": " .. tonumber(event.event_id) .. ", payload_start_pointer = " .. event.payload_start_pointer .. ", payload_length = " .. event.payload_length)
	end
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	DEBUG("ParseNextChunk", #chunk, chunk)

	-- printf("Buffer contents before parsing: %s", eventBuffer)
	local eventBuffer = self.eventBuffer
	local writeBuffer = ffi_cast("lj_writebuffer_t*", self.state.data)

	-- Absolutely worst case upper bound: One char is sent at a time, and all chars trigger an event (VERY defensive)
	-- This could probably be reduced to minimize overhead, but then chunks are limited by the OS's socket buffer size anyway...
	local maxBufferSizeToReserve = #chunk * ffi_sizeof("llhttp_event_t") / 8 -- bits -> bytes
	local ptr, len = eventBuffer:reserve(maxBufferSizeToReserve)


		--TODO raise error event that can be used to DC client or send an error code
	-- local ptr, len = eventBuffer:reserve(#chunk * ffi_sizeof("llhttp_event_t"))
	-- printf("Reserved %s bytes in buffer %s (requested: %s, total size: %s) - %s", len, ptr, maxBufferSizeToReserve, #eventBuffer, c)

	-- This is only used internally by the llhttp-ffi layer to queue events in order, and then we can commit as many bytes to the buffer
	writeBuffer.size = len
	writeBuffer.ptr = ptr
	writeBuffer.used = 0

	llhttp_execute(self.state, chunk, #chunk)
		-- printf("llhttp used %d bytes of the available %d", writeBuffer.used, writeBuffer.size)
		if writeBuffer.used > 0 then
			DEBUG("Total event buffer size: " .. tonumber(writeBuffer.size) .. " bytes")
			DEBUG("Events triggered by last chunk used: " .. tonumber(writeBuffer.used) .. " bytes")
			-- If nothing needs to be written, this can cause segfaults?
			eventBuffer:commit(writeBuffer.used)
			-- print("buffer_commit OK")
			eventBuffer:reset()
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
	eventBuffer:reset()
end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

return IncrementalHttpParser