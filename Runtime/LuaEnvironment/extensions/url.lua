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

	self.state = stateOverride or "SCHEME_START_STATE"

	encoding = getOutputEncoding(encoding)

	self.buffer = ""
	self.atSignSeen = false
	self.insideBrackets = false
	self.passwordTokenSeen = false

	self.pointer = 1
	self.EOF_CODE_POINT = #input

	while self.pointer <= self.EOF_CODE_POINT do
		self:AdvanceFSM(input)
		self.pointer = self.pointer + 1
	end

	return url
end

function URL:Dump()
	dump(self)
end

function URL:AdvanceFSM(input)
	local pointer = self.pointer
	local state = self.state

	local c = string.sub(input, pointer, pointer)
	local remaining = string.sub(input, pointer + 1)

	self.c = c
	self.remaining = remaining

	local handler = self[state]
	if not handler then
		ERROR(format("Failed to advance Basic URL parser FSM from state %s (no such state exists)", state))
		return
	end

	handler(self, input)
end

function URL:SCHEME_START_STATE(input)
	DEBUG("SCHEME_START_STATE", input)
	self:Dump()
	-- NYI
end


return URL