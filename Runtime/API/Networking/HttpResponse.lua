local HttpResponse = {}

function HttpResponse:Constructor(responseObject)
	-- TODO
end

HttpResponse.__call = HttpResponse.Constructor
setmetatable(HttpResponse, HttpResponse)

return HttpResponse
