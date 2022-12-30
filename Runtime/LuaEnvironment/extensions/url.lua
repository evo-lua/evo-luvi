local URL = {}

local url = {}

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

local function createNewUrlRecord()
	DEBUG("createNewUrlRecord")
	return urlRecord -- TBD return new instance
end

local function hasLeadingControlZeroOrSpace(input) DEBUG("hasLeadingControlZeroOrSpace") end
local function hasTrailingControlZeroOrSpace(input) DEBUG("hasTrailingControlZeroOrSpace") end
local function removeLeadingControlZeroOrSpace(input) DEBUG("removeLeadingControlZeroOrSpace") end
local function removeTrailingControlZeroOrSpace(input) DEBUG("removeTrailingControlZeroOrSpace") end
local function validationError(input) DEBUG("validationError") end
local function containsAsciiTabOrNewLine(input) DEBUG("containsAsciiTabOrNewLine") end
local function removeAllAsciiTabsOrNewLines(input) DEBUG("removeAllAsciiTabsOrNewLines") end
local function getOutputEncoding(input) DEBUG("getOutputEncoding") end

-- This implementation is a direct translation of https://url.spec.whatwg.org/#concept-basic-url-parser
local function parseBasicURL(input, base, encoding, url, optionalStateOverride)
	if not url then
		url = createNewUrlRecord()
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

	local state = optionalStateOverride or BASIC_URL_PARSER_STATES.SCHEME_START_STATE

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

-- function url.create(input, base)
-- 	local instance = {}

-- 	--  toUSVString is not needed. [Why?]
--     input = tostring(input)
--     local base_context;
--     if (base ~= nil) then
--       base_context = url.create(base).context
-- 	end
--     instance.context = URLContext();
--     parse(input, -1, base_context, nil,
--           FunctionPrototypeBind(onParseComplete, this),
--           FunctionPrototypeBind(onParseError, this, input));

-- 	return instance
-- end

function url.create(input, base)
	return parseBasicURL(input, base)
end

return url