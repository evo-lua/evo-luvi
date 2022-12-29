local client = C_Networking.HttpClient()

local requestString = "GET / HTTP/1.1\r\n\r\n"

function client:TCP_CONNECTION_ESTABLISHED()
	self:SendHttpRequest(requestString)
end