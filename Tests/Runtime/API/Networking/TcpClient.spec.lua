local TcpSocket = C_Networking.TcpSocket
local TcpClient = C_Networking.TcpClient

describe("TcpClient", function()
	describe("Constructor", function()
		it("should start connecting immediately if a valid host name and port were passed", function()
			local function codeUnderTest()
				TcpClient("127.0.0.1", 23456)
			end
			assertFunctionCalls(codeUnderTest, TcpClient, "StartConnecting")
		end)

		it("should use the default socket creation parameters if any are missing", function()
			local client = TcpClient()
			assertEquals(client:GetPort(), TcpSocket.DEFAULT_SOCKET_CREATION_OPTIONS.port)
			assertEquals(client:GetHostName(), TcpSocket.DEFAULT_SOCKET_CREATION_OPTIONS.hostName)
		end)

		it("should register prototypes for all customizable event handlers", function()
			local expectedEventHandlers = {
				"TCP_CONNECTION_ESTABLISHED",
				"TCP_CHUNK_RECEIVED",
				"TCP_WRITE_SUCCEEDED",
				"TCP_WRITE_FAILED",
				"TCP_SESSION_STARTED",
				"TCP_SESSION_ENDED",
				"TCP_SOCKET_CLOSED",
				"TCP_SOCKET_ERROR",
			}

			local client = TcpClient()

			for _, eventID in ipairs(expectedEventHandlers) do
				assertEquals(type(client[eventID]), "function", "Should register listener for event " .. eventID)
			end

			client:Disconnect()
		end)
	end)
end)
