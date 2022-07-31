local format = format
local pairs = pairs
local type = type

local C_EventSystem = {
	EventListenerMixin = require("EventListenerMixin"),
	listeners = {},
}

function C_EventSystem.AddEventListener(eventID, listener)
	if type(eventID) ~= "string" or type(listener) ~= "table" then
		error("Usage: AddEventListener(eventID : string, listener : table)", 0)
	end

	if type(listener.OnEvent) ~= "function" then
		error(format("Failed to AddEventListener for %s (listener must implement an OnEvent method)", eventID), 0)
	end

	C_EventSystem.listeners[eventID] = C_EventSystem.listeners[eventID] or {}

	if type(C_EventSystem.listeners[eventID][listener]) == "table" then
		error(format("Failed to AddEventListener for %s (already registered)", eventID), 0)
	end
	C_EventSystem.listeners[eventID][listener] = listener
end

function C_EventSystem.RemoveEventListener(eventID, listener)
	if type(eventID) ~= "string" or type(listener) ~= "table" then
		error("Usage: RemoveEventListener(eventID : string, listener : table)", 0)
	end

	local registeredListeners = C_EventSystem.listeners[eventID]
	if not registeredListeners then
		error(
			format(
				"Failed to remove event listener %s for event %s (no listeners are registered for this event)",
				listener,
				eventID
			),
			0
		)
	end

	registeredListeners[listener] = nil

	return true
end

function C_EventSystem.TriggerEvent(eventID, payload)
	if type(eventID) ~= "string" or (payload and type(payload) ~= "table") then
		error("Usage: TriggerEvent(eventID : string, payload : table?)", 0)
	end

	EVENT(eventID, payload)

	local registeredListeners = C_EventSystem.listeners[eventID]
	if not registeredListeners then
		return
	end

	for listenerID, listener in pairs(registeredListeners) do
		listener:OnEvent(eventID, payload)
	end
end

function C_EventSystem.GetRegisteredEventListeners(eventID)
	return C_EventSystem.listeners[eventID] or {}
end

return C_EventSystem
