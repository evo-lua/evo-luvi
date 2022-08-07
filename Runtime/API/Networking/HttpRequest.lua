local pairs = pairs
local setmetatable = setmetatable
local table_concat = table.concat

local HttpRequest = {}

function HttpRequest:Constructor(requestObject)
	requestObject = requestObject
		or {
			method = "GET",
			requestedURL = "/",
			versionString = "HTTP/1.1",
			headers = {},
			body = "",
		}

	setmetatable(requestObject, self)

	return requestObject
end

HttpRequest.__call = HttpRequest.Constructor
HttpRequest.__index = HttpRequest

function HttpRequest:ToString()
	local tokens = {}

	local statusLine = self.method .. " " .. self.requestedURL .. " " .. self.versionString

	tokens[#tokens + 1] = statusLine

	for key, value in pairs(self.headers) do
		tokens[#tokens + 1] = key .. ": " .. value
	end

	if #self.body > 0 then
		tokens[#tokens + 1] = "\r\n" -- Separate headers and body
		tokens[#tokens + 1] = self.body
	end
	local requestString = table_concat(tokens, "\r\n")

	return requestString
end

setmetatable(HttpRequest, HttpRequest)

return HttpRequest
