local ffi = require("ffi")

local ipairs = ipairs
local setmetatable = setmetatable
local table_concat = table.concat

local HttpRequest = {
	cdefs = [[
		typedef struct HttpRequest {
			void* methodStringBuffer;
		}
	]],
}

ffi.cdef(HttpRequest.cdefs)

function HttpRequest:Construct(requestObject)
	requestObject = requestObject
		or {
			method = "",
			requestedURL = "",
			versionString = "",
			headers = {},
			body = "",
		}

	setmetatable(requestObject, self)

	return requestObject
end

HttpRequest.__call = HttpRequest.Construct
HttpRequest.__index = HttpRequest

function HttpRequest:Reset()
	self.method = ""
	self.requestedURL = ""
	self.versionString = ""
	self.headers = {}
	self.body = ""
end

function HttpRequest:ToString()
	local tokens = {}

	local statusLine = self.method .. " " .. self.requestedURL .. " " .. self.versionString

	tokens[#tokens + 1] = statusLine

	for index, fieldName in ipairs(self.headers) do
		-- The headers are split into a simple dictionary (for fast lookups) and a map to maintain the order of arrival (for serialization)
		tokens[#tokens + 1] = fieldName .. ": " .. self.headers[fieldName]
	end

	if #self.body > 0 then
		tokens[#tokens + 1] = self.body
	end

	tokens[#tokens + 1] = "\r\n" -- Signals EOF

	local requestString = table_concat(tokens, "\r\n")
	return requestString
end

setmetatable(HttpRequest, HttpRequest)

return HttpRequest
