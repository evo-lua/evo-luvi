local string_buffer = require("string.buffer")
local buffer_new = string_buffer.new
local table_clear = require("table.clear")

local table_concat = table.concat
local tostring = tostring
local ipairs = ipairs

local DEFAULT_BUFFER_SIZE_IN_BYTES = 64 -- Should avoid buffer resizes in most cases, but also doesn't waste too much memory

local HttpMessage = {}

function HttpMessage:Construct()
	local instance = {
		method = buffer_new(16), -- No valid HTTP method uses more than 13 characters
		requestTarget = buffer_new(DEFAULT_BUFFER_SIZE_IN_BYTES),
		httpVersion = buffer_new(8), -- HTTP/x.y
		statusCode = buffer_new(DEFAULT_BUFFER_SIZE_IN_BYTES),
		reasonPhrase = buffer_new(DEFAULT_BUFFER_SIZE_IN_BYTES),
		headers = {},
		body = buffer_new(DEFAULT_BUFFER_SIZE_IN_BYTES),
	}

	setmetatable(instance, self)

	return instance
end

function HttpMessage:Reset()
	self.method:reset()
	self.requestTarget:reset()
	self.httpVersion:reset()
	self.statusCode:reset()
	self.reasonPhrase:reset()
	self.body:reset()

	table_clear(self.headers)
end

function HttpMessage:IsEmpty()
	local areHeadersEmpty = (#self.headers == 0)
	local areFieldsUninitialized = (#self.method == 0)
		and (#self.requestTarget == 0)
		and (#self.httpVersion == 0)
		and (#self.statusCode == 0)
		and (#self.reasonPhrase == 0)
		and (#self.body == 0)
	return areHeadersEmpty and areFieldsUninitialized
end

-- TODO tests
function HttpMessage:AppendHeaderValue(key, startPointer, length)
	-- self.headerFields[key] = self.headerFields[key] or buffer_new()
	-- self.headerFields[key]:putcdata(startPointer, length)
end

function HttpMessage:IsRequest()
	local areResponseFieldsUninitialized = (#self.statusCode == 0) and (#self.reasonPhrase == 0)
	local areRequestFieldsInitialized = (#self.method > 0) and (#self.requestTarget > 0) and (#self.httpVersion > 0)

	return areResponseFieldsUninitialized and areRequestFieldsInitialized
end

function HttpMessage:IsResponse()
	local areMandatoryResponseFieldsInitialized = (#self.statusCode > 0) and (#self.httpVersion > 0)
	local areRequestFieldsUninitialized = (#self.requestTarget == 0) and (#self.method == 0)

	return areMandatoryResponseFieldsInitialized and areRequestFieldsUninitialized
end

function HttpMessage:ToString()
	local lines = {}

	if self:IsEmpty() then
		return ""
	end

	if self:IsRequest() then
		lines[#lines + 1] = tostring(self.method)
			.. " "
			.. tostring(self.requestTarget)
			.. " "
			.. tostring(self.httpVersion)
	end

	if self:IsResponse() then
		lines[#lines + 1] = tostring(self.httpVersion)
			.. " "
			.. tostring(self.statusCode)
			.. " "
			.. tostring(self.reasonPhrase)
	end

	for index, header in ipairs(self.headers) do
		local key, values = header[1], header[2]
		lines[#lines + 1] = tostring(key) .. ": " .. tostring(values)
	end

	if #self.body > 0 then
		lines[#lines + 1] = tostring(self.body)
	end
	lines[#lines + 1] = "\r\n" -- Must end any message with two line breaks

	return table_concat(lines, "\r\n")
end

HttpMessage.__call = HttpMessage.Construct
HttpMessage.__index = HttpMessage

setmetatable(HttpMessage, HttpMessage)

return HttpMessage
