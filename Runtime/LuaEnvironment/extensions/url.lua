local urlHost = ""

local urlRecord = {
	scheme = "",
	username = "",
	password = "",
	host = "",
}

local function hasLeadingControlZeroOrSpace(input) DEBUG("hasLeadingControlZeroOrSpace") end
local function hasTrailingControlZeroOrSpace(input) DEBUG("hasTrailingControlZeroOrSpace") end
local function removeLeadingControlZeroOrSpace(input) DEBUG("removeLeadingControlZeroOrSpace") end
local function removeTrailingControlZeroOrSpace(input) DEBUG("removeTrailingControlZeroOrSpace") end
local function validationError(input) DEBUG("validationError") end
local function containsAsciiTabOrNewLine(input) DEBUG("containsAsciiTabOrNewLine") end
local function removeAllAsciiTabsOrNewLines(input) DEBUG("removeAllAsciiTabsOrNewLines") end
local function getOutputEncoding(input) DEBUG("getOutputEncoding") end

local URL = {}

function URL:Construct()
	local instance = {}

	setmetatable(instance, self)

	return instance
end

URL.__call = URL.Construct
setmetatable(URL, URL)

-- This implementation is a direct translation of https://url.spec.whatwg.org/#concept-basic-url-parser
function URL:Parse(input, base, encoding, url, stateOverride)
	if not url then
		url = URL()
		if hasLeadingControlZeroOrSpace(input) or hasTrailingControlZeroOrSpace(input) then
			validationError(input, base)
			removeLeadingControlZeroOrSpace(input)
			removeTrailingControlZeroOrSpace(input)
		end
	end

	if containsAsciiTabOrNewLine(input) then
		validationError(input, base)
		removeAllAsciiTabsOrNewLines(input)
	end

	local state = stateOverride or "SCHEME_START_STATE"

	encoding = getOutputEncoding(encoding)

	local buffer = ""
	local atSignSeen, insideBrackets, passwordTokenSeen = false, false, false
	local pointer = 1

	local EOF_CODE_POINT = #input

	while pointer <= EOF_CODE_POINT do
		self:AdvanceFSM(state, input, pointer)
		pointer = pointer + 1
	end

	return url
end


function URL:AdvanceFSM(state, input, pointer)
	local c = string.sub(input, pointer, pointer)
	local remaining = string.sub(input, pointer + 1)
	DEBUG("advanceFSM", state, pointer, c, remaining)

	local handler = self[state]
	if not handler then
		ERROR(format("Failed to advance Basic URL parser FSM from state %s (no such state exists)", state))
		return
	end

	handler(self, input, pointer)
end

function URL:SCHEME_START_STATE(input, pointer)
	DEBUG("SCHEME_START_STATE", input, pointer)
	-- NYI
end


return URL