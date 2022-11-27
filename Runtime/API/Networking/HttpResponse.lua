local HttpResponse = {}

-- TODO HttpMessage, combine request and response? serialization code is almost identical
function HttpResponse:Construct(responseObject)
	responseObject = responseObject
		or {
			versionString = "", -- protocolVersion
			statusCode = -1,
			statusText = "",
			headers = {},
			body = "",
		}
	setmetatable(responseObject, self)

	return responseObject
end

HttpResponse.__call = HttpResponse.Construct
HttpResponse.__index = HttpResponse

local table_concat = table.concat

function HttpResponse:ToString()
	local tokens = {}

	local statusLine = self.versionString .. " " .. self.statusCode .. " " .. self.statusText

	tokens[#tokens + 1] = statusLine

	for index, fieldName in ipairs(self.headers) do
		-- The headers are split into a simple dictionary (for fast lookups) and a map to maintain the order of arrival (for serialization)
		tokens[#tokens + 1] = fieldName .. ": " .. self.headers[fieldName]
	end

	if #self.body > 0 then
		tokens[#tokens + 1] = self.body
	end

	tokens[#tokens + 1] = "\r\n" -- Signals EOF

	local responseString = table_concat(tokens, "\r\n")
	return responseString
end

setmetatable(HttpResponse, HttpResponse)

return HttpResponse
