local ffi = require("ffi")
local string_buffer = require("string.buffer")
local buffer = require("string.buffer")

local DEFAULT_EVENTLOG_BUFFER_SIZE_IN_BYTES = 255 -- We can let LuaJIT handle this, but it also doesn't hurt...


local IncrementalHttpParser = {}

function IncrementalHttpParser:Construct()
	local instance = {
		state = ffi.new("llhttp_t"),
		-- settings = ffi.new("llhttp_settings_t"),
	}


	-- The parser's userdata can be used as a event log to avoid C->Lua callbacks (extremely slow)
	-- Setting up the buffer from Lua is much simpler since we don't need to deal with the Lua state directly here
	instance.eventLogBuffer = buffer.new(DEFAULT_EVENTLOG_BUFFER_SIZE_IN_BYTES)
	instance.state.data = instance.eventLogBuffer:ref() -- Can only store void pointer, which we will cast in C to SBuf* before using it
	-- instance.eventLogBuffer:put("test#123")

	setmetatable(instance, { __index = self })

	return instance
end

setmetatable(IncrementalHttpParser, { __call = IncrementalHttpParser.Construct })

return IncrementalHttpParser