-- Terminology used: See RFC 9112
local HttpMessage = {
	startLine = "", -- requestLine or statusLine
	headerFieldLines = {},
	messageBody = "",
}

function HttpMessage:Construct()
	-- TODO reuse existing code
end

function HttpMessage:IsRequest()
	-- return self:IsRequestLine(self.startLine)
end

function HttpMessage:IsRequestLine(buffer) end

function HttpMessage:IsResponse()
	-- return self:IsStatusLine(self.startLine)
end

function HttpMessage:IsStatusLine(buffer) end
