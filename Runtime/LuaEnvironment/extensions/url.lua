-- TBD move to stringx or inline?
function _G.string:startswith(start)
    return self:sub(1, #start) == start
end

---

local SCHEME_START_STATE = "SCHEME_START_STATE"
local SCHEME_STATE = "SCHEME_STATE"
local NO_SCHEME_STATE = "NO_SCHEME_STATE"
local FILE_STATE = "FILE_STATE"
local SPECIAL_RELATIVE_OR_AUTHORITY_STATE = "SPECIAL_RELATIVE_OR_AUTHORITY_STATE"
local SPECIAL_AUTHORITY_SLASHES_STATE = "SPECIAL_AUTHORITY_SLASHES_STATE"
local PATH_OR_AUTHORITY_STATE = "PATH_OR_AUTHORITY_STATE"
local OPAQUE_PATH_STATE = "OPAQUE_PATH_STATE"


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

local PLUS_SIGN = 0x2B
local MINUS_SIGN = 0x2D
local FULL_STOP = 0x2E
local DIGIT_ZERO = 0x30
local DIGIT_NINE = 0x39
local COLON = 0x3A

local function isAsciiNumeric(character) DEBUG("isAsciiNumeric")
	local codePoint = string.byte(character)
	return codePoint >= DIGIT_ZERO and codePoint <= DIGIT_NINE
end

local function isAsciiAlphaNumeric(character) DEBUG("isAsciiAlphaNumeric")
	return isAsciiNumeric(character) or isAsciiAlpha(character)
end

local function isPlus(character) DEBUG("isPlus")
	local codePoint = string.byte(character)
	return codePoint == PLUS_SIGN
end

local function isMinus(character) DEBUG("isMinus")
	local codePoint = string.byte(character)
	return codePoint == MINUS_SIGN
end

local function isDot(character) DEBUG("isDot")
	local codePoint = string.byte(character)
	return codePoint == FULL_STOP
end

local function isColon(character) DEBUG("isColon")
	local codePoint = string.byte(character)
	return codePoint == COLON
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
	-- local url = URL()
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
		self:AdvanceFSM(input, base)
		self.pointer = self.pointer + 1
	end

	self:Dump() -- TODO Remove
	return self
	-- return url -- TBD
end

local specialSchemesWithDefaultPorts = {
	ftp = 21,
	file = 0, -- Technically, nil... but we can't use that in Lua since it would unset the key
	http = 80,
	https = 443,
	ws = 80,
	wss = 443,
}

local function isSpecialScheme(scheme)
	return specialSchemesWithDefaultPorts[scheme] ~= nil
end

function URL:IsSpecial()
	return isSpecialScheme(self.scheme)
end

function URL:Dump()
	dump(self)
end

function URL:AdvanceFSM(input, base)
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

	handler(self, input, base)
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

function URL:SCHEME_STATE(input, base) DEBUG(self.state, input, base)
	local c = self.c
	if isAsciiAlphaNumeric(c) or isPlus(c) or isMinus(c) or isDot(c) then
		self.buffer = self.buffer .. string.lower(c)
	elseif isColon(c) then
		self.scheme = self.buffer
		self.buffer = ""

		if self.scheme == "file" then
			if not self.scheme:startswith("//") then validationError("Expected // after file scheme in SCHEME_STATE") end
			self.state = FILE_STATE
		elseif self:IsSpecial() and base ~= nil and base.scheme ~= self.scheme then
			assert(base:IsSpecial())
			self.state = SPECIAL_RELATIVE_OR_AUTHORITY_STATE
		elseif self:IsSpecial() then
			self.state = SPECIAL_AUTHORITY_SLASHES_STATE
		elseif self.remaining:startswith("/") then
			self.state = PATH_OR_AUTHORITY_STATE
			self.pointer = self.pointer + 1
		else
			self.path = ""
			self.state = OPAQUE_PATH_STATE
		end
	else
		self.buffer = ""
		self.state = NO_SCHEME_STATE
		self.pointer = 0
	end
end

local SPECIAL_AUTHORITY_IGNORE_SLASHES_STATE = "SPECIAL_AUTHORITY_IGNORE_SLASHES_STATE"
local RELATIVE_STATE = "RELATIVE_STATE"
local AUTHORITY_STATE = "AUTHORITY_STATE"
local PATH_STATE = "PATH_STATE"
local RELATIVE_SLASH_STATE = "RELATIVE_SLASH_STATE"
local QUERY_STATE = "QUERY_STATE"
local FRAGMENT_STATE = "FRAGMENT_STATE"

function URL:NO_SCHEME_STATE(input, base) DEBUG(self.state, input, base) end

function URL:SPECIAL_RELATIVE_OR_AUTHORITY_STATE(input, base) DEBUG(self.state, input, base)
	local c = self.c
	if c == "/" and self.remaining:startswith("/") then
		self.state = SPECIAL_AUTHORITY_IGNORE_SLASHES_STATE
		self.pointer = self.pointer + 1
	else
		validationError("Expected authority slashes or relative path?")
		self.state = RELATIVE_STATE
		self.pointer = self.pointer - 1
	end
end

function URL:SPECIAL_AUTHORITY_SLASHES_STATE(input, base) DEBUG(self.state, input, base)

end

function URL:PATH_OR_AUTHORITY_STATE(input, base) DEBUG(self.state, input, base)
	if self.c == "/" then
		self.state = AUTHORITY_STATE
	else
		self.state = PATH_STATE
		self.pointer = self.pointer - 1
	end
end

function URL:OPAQUE_PATH_STATE(input, base) DEBUG(self.state, input, base) end
function URL:SPECIAL_AUTHORITY_IGNORE_SLASHES_STATE(input, base) DEBUG(self.state, input, base) end

function URL:RELATIVE_STATE(input, base) DEBUG(self.state, input, base)
	assert(base.scheme ~= "file", "Base scheme must not be 'file'")
	self.scheme = base.scheme

	local c = self.c
	if c == "/" then
		self.state = RELATIVE_SLASH_STATE
	elseif self:IsSpecial() and c == "\\" then
		validationError("Unexpected backslash in RELATIVE_STATE")
		self.state = RELATIVE_SLASH_STATE
	else
		self.username = base.username
		self.password = base.password
		self.host = base.host
		self.port = base.port
		self.path = base.path -- Cloning doesn't make sense since strings are immutable
		self.query = base.query

		if c == "?" then
			self.query = ""
			self.state = QUERY_STATE
		elseif c == "#" then
			self.fragment = ""
			self.state = FRAGMENT_STATE
		elseif c ~= nil then -- EOF_CODE_POINT ?
			self.query = nil
			self:ShortenPath()
			self.state = PATH_STATE
			self.pointer = self.pointer - 1
		end
	end
end

function URL:AUTHORITY_STATE(input, base) DEBUG(self.state, input, base) end
function URL:PATH_STATE(input, base) DEBUG(self.state, input, base) end
function URL:RELATIVE_SLASH_STATE(input, base) DEBUG(self.state, input, base) end
function URL:QUERY_STATE(input, base) DEBUG(self.state, input, base) end
function URL:FRAGMENT_STATE(input, base) DEBUG(self.state, input, base) end

local function isNormalizedWindowsDriveLetter()
	error("Usage of isNormalizedWindowsDriveLetter makes no sense, unless path is an object?")
end

function URL:ShortenPath()
	local hasOpaquePath = (type(self.path) == "string")
	assert(not hasOpaquePath, "URL must not have an opaque path")

	local path = self.path
	-- TBD when can this even happen? Path must not be a string? Don't think we'll ever see this here?
	if self.scheme == "file" and #path == 1 and isNormalizedWindowsDriveLetter(self.c) then return end

	self.path = string.sub(self.path, 1, #path-1) -- or "" ?
end

return URL