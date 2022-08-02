local ipairs = ipairs
local string_explode = string.explode
local string_lower = string.lower
local string_upper = string.upper
local string_sub = string.sub
local type = type

local EventListenerMixin = {
	DEFAULT_EVENT_HANDLER_NAME = "OnEvent",
	registeredEvents = {},
}

function EventListenerMixin:OnEvent(eventID, payload)
	local defaultListenerName = self:GetDefaultListenerName(eventID)
	local eventListener = self[defaultListenerName]

	if type(eventListener) ~= "function" then
		return
	end

	eventListener(self, eventID, payload)
end

function EventListenerMixin:RegisterEvent(eventID)
	C_EventSystem.AddEventListener(eventID, self)
	self.registeredEvents[eventID] = true
end

function EventListenerMixin:UnregisterEvent(eventID)
	C_EventSystem.RemoveEventListener(eventID, self)
	self.registeredEvents[eventID] = nil
end

function EventListenerMixin:UnregisterAllEvents()
	for eventID, isRegistered in pairs(self.registeredEvents) do
		self:UnregisterEvent(eventID)
	end
end

function EventListenerMixin:IsEventRegistered(eventID)
	if not self.registeredEvents[eventID] then
		return false
	end

	return true
end

local function string_capitalize(inputString)
	local firstLetter = string_sub(inputString, 1, 1)
	local rest = string_sub(inputString, 2)
	return string_upper(firstLetter) .. string_lower(rest)
end

function EventListenerMixin:GetDefaultListenerName(eventID)
	if type(eventID) ~= "string" then
		return self.DEFAULT_EVENT_HANDLER_NAME
	end

	-- This simple heuristic should work for all event IDs following the standard naming conventions
	local tokens = string_explode(eventID, "_")
	local defaultListenerName = "On"
	for index, token in ipairs(tokens) do
		local pascalCasedToken = string_capitalize(token)
		defaultListenerName = defaultListenerName .. pascalCasedToken
	end

	return defaultListenerName
end

return EventListenerMixin
