local C_EventLog = {
	history = {}
}

function C_EventLog.Enable()
	C_EventLog.Clear()
	NOTICE("Event logging is now ON")
end

function C_EventLog.Clear()
	table.wipe(C_EventLog.history)
	DEBUG("[C_EventLog] History cleared")
end

local table_copy = table.copy -- TODO NYI

function C_EventLog.GetHistory()
	return table_copy(C_EventLog.history)
end

function C_EventLog.Disable()
	NOTICE("Event logging is now OFF")
end

return C_EventLog