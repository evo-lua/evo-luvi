local urlHost = ""

local urlRecord = {
	scheme = "",
	username = "",
	password = "",
	host = "",
}

local SCHEME_START_STATE = "SCHEME_START_STATE"
local SCHEME_STATE = "SCHEME_STATE"
local NO_SCHEME_STATE = "NO_SCHEME_STATE"

-- TBD Move to unicode namespace?
local LATIN_CAPITAL_LETTER_A = 0x41
local LATIN_CAPITAL_LETTER_Z = 0x5A
local LATIN_SMALL_LETTER_A = 0x61
local LATIN_SMALL_LETTER_Z = 0x7A

local function hasLeadingControlZeroOrSpace(input) DEBUG("hasLeadingControlZeroOrSpace") end
local function hasTrailingControlZeroOrSpace(input) DEBUG("hasTrailingControlZeroOrSpace") end
local function removeLeadingControlZeroOrSpace(input) DEBUG("removeLeadingControlZeroOrSpace") end
local function removeTrailingControlZeroOrSpace(input) DEBUG("removeTrailingControlZeroOrSpace") end
local function validationError(input) DEBUG("validationError") end
local function containsAsciiTabOrNewLine(input) DEBUG("containsAsciiTabOrNewLine") end
local function removeAllAsciiTabsOrNewLines(input) DEBUG("removeAllAsciiTabsOrNewLines") end
-- local function getOutputEncoding(input) DEBUG("getOutputEncoding") end

local function isAsciiUpperAlpha(character) DEBUG("isAsciiUpperAlpha")
	local codePoint = string.byte(character)
	return codePoint >= LATIN_CAPITAL_LETTER_A and codePoint <= LATIN_CAPITAL_LETTER_Z
end

local function isAsciiLowerAlpha(character) DEBUG("isAsciiLowerAlpha")
	local codePoint = string.byte(character)
	return codePoint >= LATIN_SMALL_LETTER_A and codePoint <= LATIN_SMALL_LETTER_Z
end

local function isAsciiAlpha(character) DEBUG("isAsciiAlpha")
	return isAsciiUpperAlpha(character) or isAsciiLowerAlpha(character)
end

local URL = {}

function URL:Construct()
	local instance = {}

	setmetatable(instance, self)

	return instance
end

URL.__call = URL.Construct
setmetatable(URL, URL)

-- This implementation is a direct translation of https://url.spec.whatwg.org/#concept-basic-url-parser
function URL:Parse(input, base)
	local url = URL()
	if hasLeadingControlZeroOrSpace(input) or hasTrailingControlZeroOrSpace(input) then
		validationError(input, base)
		removeLeadingControlZeroOrSpace(input)
		removeTrailingControlZeroOrSpace(input)
	end

	if containsAsciiTabOrNewLine(input) then
		validationError(input, base)
		removeAllAsciiTabsOrNewLines(input)
	end

	self.state = SCHEME_START_STATE

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

function URL:SCHEME_START_STATE(input) DEBUG(self.state, input)

	local c = self.c
	if isAsciiAlpha(c) then
		self.buffer = self.buffer .. string.lower(c)
		self.state = SCHEME_STATE
	else
		self.state = NO_SCHEME_STATE
		self.pointer = self.pointer - 1
	end
end

function URL:SCHEME_STATE(input) DEBUG(self.state, input)

end

function URL:NO_SCHEME_STATE(input) DEBUG(self.state, input)

end

return URL