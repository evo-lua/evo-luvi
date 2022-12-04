local string_buffer = require("string.buffer")
local buffer_new = string_buffer.new

-- Terminology used: See RFC 9112
local HttpMessage = {}

function HttpMessage:Construct()
	-- TODO reuse existing code

	local instance = {
		startLine = buffer_new(), -- requestLine or statusLine
		headerFieldLines = {},
		messageBody = buffer_new(),
	}

	setmetatable(instance, self)

	return instance
end

function HttpMessage:IsRequest()
	-- return self:IsRequestLine(self.startLine)
end

function HttpMessage:IsRequestLine(buffer) end

function HttpMessage:IsResponse()
	-- return self:IsStatusLine(self.startLine)
end

function HttpMessage:IsStatusLine(buffer) end

HttpMessage.__call = HttpMessage.Construct
HttpMessage.__index = HttpMessage

setmetatable(HttpMessage, HttpMessage)

return HttpMessage