local TcpServer = C_Networking.TcpServer
local TcpClient = C_Networking.TcpClient

local serverOptions = {
	port = 12345,
	hostName = "127.0.0.1",
}
local CustomProtocolServer = TcpServer(serverOptions)

-- Should buffer until message is complete, decode, compute response (if any)
local function MyCustomProtocolHandler(chunk)
	-- In reality, chunks may arrive piecemeal (simplification; in reality, this needs some buffering)
	local messages = string.explode(chunk, "\n")

	local responses = {}
	for index, message in ipairs(messages) do
		if message == "PING" then
			table.insert(responses, "PONG\n")
		else
			table.insert(responses, "ERROR\n")
		end
	end

	return responses
end

function CustomProtocolServer:TCP_CHUNK_RECEIVED(clientSocket, chunk)
	print("CustomProtocolServer: TCP_CHUNK_RECEIVED", chunk)
	local responses = MyCustomProtocolHandler(chunk)
	for index, response in ipairs(responses) do
		self:Send(clientSocket, response)
	end
end

-- For demonstration purposes, connect to the server locally
local client = TcpClient(serverOptions.hostName, serverOptions.port)
	function client.TCP_CONNECTION_ESTABLISHED()
	print("client: TCP_CONNECTION_ESTABLISHED")
	client:Send("PING\n") -- Causes response: PONG
	client:Send("Hello?\n") -- Causes response: ERROR
end

function client:TCP_CHUNK_RECEIVED(chunk)
	-- Again, glossing over buffering etc here.

	print("client: TCP_CHUNK_RECEIVED", chunk)

	-- Again, have to buffer etc. here (which we ignore)
	local messages = string.explode(chunk, "\n")

	for index, message in ipairs(messages) do
		if message == "ERROR" then
			print("Protocol error! Disconnecting ...")
			self:Disconnect()
			CustomProtocolServer:StopListening() -- Would normally continue to run
		else
			print("Message OK: " .. message)
		end
	end
end