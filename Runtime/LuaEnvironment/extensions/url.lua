local urlHost = ""

local urlRecord = {
	scheme = "",
	username = "",
	password = "",
	host = "",
}

local BASIC_URL_PARSER_STATES = {
	SCHEME_START_STATE = function(input, pointer)
		DEBUG("SCHEME_START_STATE")
		-- NYI
	end
}

local function advanceFSM(state, input, pointer)
	local c = string.sub(input, pointer, pointer)
	local remaining = string.sub(input, pointer + 1)
	DEBUG("advanceFSM", state, pointer, c, remaining)

	local processInput = BASIC_URL_PARSER_STATES[state]
	if not processInput then
		ERROR(format("Failed to advance Basic URL parser FSM from state %s (no such state exists)", state))
		return
	end

	processInput(input, pointer)
end

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

	local state = stateOverride or BASIC_URL_PARSER_STATES.SCHEME_START_STATE

	encoding = getOutputEncoding(encoding)

	local buffer = ""
	local atSignSeen, insideBrackets, passwordTokenSeen = false, false, false
	local pointer = 1

	local EOF_CODE_POINT = #input

	while pointer <= EOF_CODE_POINT do
		advanceFSM(state, input, pointer)
		pointer = pointer + 1
	end

	return url
end

return URL