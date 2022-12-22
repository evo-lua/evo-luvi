local C_Networking = {
	TcpSocket = require("TcpSocket"),
	TcpServer = require("TcpServer"),
	TcpClient = require("TcpClient"),
	IncrementalHttpParser = require("IncrementalHttpParser"),
	AsyncHandleMixin = require("AsyncHandleMixin"),
	AsyncStreamMixin = require("AsyncStreamMixin"),
	AsyncSocketMixin = require("AsyncSocketMixin"),
}

local ffi = require("ffi")

local ffi_cast = ffi.cast
local ffi_sizeof = ffi.sizeof
local table_insert = table.insert

-- Whether or not these really belong here is highly questionable. Will have to revisit this later...
function C_Networking.DecodeBufferAsArrayOf(stringBuffer, cType)
	local bufferedEvents = {}

	for index = 0, C_Networking.GetNumElementsOfType(stringBuffer, cType) - 1, 1 do
		local event = C_Networking.DecodeElementAtBufferIndexAs(stringBuffer, index, cType)
		table_insert(bufferedEvents, event)
	end

	return bufferedEvents
end

function C_Networking.GetNumElementsOfType(stringBuffer, cType)
	return #stringBuffer / ffi_sizeof(cType)
end

function C_Networking.DecodeElementAtBufferIndexAs(stringBuffer, index, cType)
	index = index or 0

	if #stringBuffer == 0 then
		return
	end

	local startPointer = stringBuffer:ref()
	local offset = index * ffi_sizeof(cType)

	-- TODO test or remove
	-- local lastValidIndex  = self:GetNumBufferedEvents() - 1
	-- if index < 0 or index > lastValidIndex then return nil end

	-- TODO no GC anchor!
	local event = ffi_cast("llhttp_event_t*", startPointer + offset)

	return event
end

return C_Networking
