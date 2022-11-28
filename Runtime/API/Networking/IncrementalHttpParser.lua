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

local DEFAULT_EVENTLOG_BUFFER_SIZE_IN_BYTES = 255 -- We can let LuaJIT handle this, but it also doesn't hurt...


local IncrementalHttpParser = {}

function IncrementalHttpParser:Construct()
	local instance = {
		state = ffi.new("llhttp_t"),
		settings = ffi.new("llhttp_settings_t"),
	}

	llhttp_settings_init(instance.settings) -- Also sets up callbacks in C (to avoid Lua/C call overhead)
	llhttp_init(instance.state, llhttp.PARSER_TYPES.HTTP_BOTH, instance.settings)

	-- The parser's userdata can be used as a event log to avoid C->Lua callbacks (extremely slow)
	-- Setting up the buffer from Lua is much simpler since we don't need to deal with the Lua state directly here
	instance.eventLogBuffer = string_buffer.new(DEFAULT_EVENTLOG_BUFFER_SIZE_IN_BYTES)
	-- instance.state.data = instance.eventLogBuffer:ref() -- Can only store void pointer, which we will cast in C to SBuf* before using it
	-- instance.state.data = instance.eventLogBuffer -- Can only store void pointer, which we will cast in C to SBuf* before using it
	instance.state.data = ffi.new("lj_writebuffer_t")

	setmetatable(instance, { __index = self })

	return instance
end

function IncrementalHttpParser:ParseNextChunk(chunk)
	DEBUG("ParseNextChunk", #chunk, chunk)
	printf("Buffer contents before parsing: %s", self.eventLogBuffer)
	local writeBuffer = ffi.cast("lj_writebuffer_t*", self.state.data)
	-- TODO reserve #chunk + buffer for events (at most 1 ID per character, which is PROBABLY far too high... but still)
	-- writeBuffer.size = #chunk * 2-- Leave some extra room for the event IDs (sketchy?)
	local ptr, len = self.eventLogBuffer:reserve(#chunk * 2) -- For small chunks, this always is 256 anyway (can't make it less wasteful)
	printf("Reserved %s bytes in buffer %s", len, ptr)
	writeBuffer.size = len
	writeBuffer.ptr = ptr
	writeBuffer.used = 0
	llhttp_execute(self.state, chunk, #chunk)
	printf("llhttp used %d bytes of the available %d", writeBuffer.used, writeBuffer.size)
	self.eventLogBuffer:commit(writeBuffer.used)
	printf("Buffer contents after parsing: %s", tostring(self.eventLogBuffer))
end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

return IncrementalHttpParser