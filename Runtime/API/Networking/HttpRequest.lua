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

	return requestObject
end

HttpRequest.__call = HttpRequest.Constructor

function HttpRequest.__tostring(requestObject)
	return "Hi"
end

setmetatable(HttpRequest, HttpRequest)

return HttpRequest
