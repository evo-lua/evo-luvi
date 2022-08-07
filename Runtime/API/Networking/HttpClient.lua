local rawget = rawget
local setmetatable = setmetatable

local TcpSocket = require("TcpSocket")
local TcpClient = require("TcpClient")

local HttpClient = {}

function HttpClient.__index(target, key)
	print(target, key)
	if rawget(HttpClient, key) ~= nil then
		print("HttpClient")
		return HttpClient[key]
	end
	if TcpClient[key] ~= nil then
		print("TcpClient")
		return TcpClient[key]
	end
	if TcpSocket[key] ~= nil then
		print("TcpSocket")
		return TcpSocket[key]
	end
	print("rawget")
	return rawget(target, key)
end

function HttpClient:Construct(hostName, port)
	print("HTTP CLIENT", hostName, port)
	local instance = TcpClient(hostName, port)
	dump(instance)
	setmetatable(instance, self)
	return instance
end

function HttpClient:SendHttpRequest(request)
	print("SendHttpRequest", request)
	self:Send(request:ToString())
end

HttpClient.__call = HttpClient.Construct
setmetatable(HttpClient, HttpClient)

function HttpClient:HTTP_REQUESTED_SENT()
	DEBUG("[HttpClient] HTTP_REQUESTED_SENT triggered")
end

function HttpClient:HTTP_RESPONSE_RECEIVED()
	DEBUG("[HttpClient] HTTP_RESPONSE_RECEIVED triggered")
end

return HttpClient
