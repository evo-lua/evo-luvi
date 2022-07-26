local TcpServer = C_Networking.TcpServer

describe("TcpServer", function()
	describe("Constructor", function()
		it("should use the default socket options if none were passed", function()
			local server = TcpServer()
			assertEquals(server:GetPort(), TcpServer:GetPort())
			assertEquals(server:GetHostName(), TcpServer:GetHostName())
			assertEquals(server:GetMaxBacklogSize(), TcpServer:GetMaxBacklogSize())
			assertEquals(server:GetURL(), TcpServer:GetURL())

			server:StopListening()
		end)

		it("should use the socket creation options if any were passed", function()
			local options = {
				port = 123,
				hostName = "0.0.0.0",
				backlogQueueSize = 42,
			}

			local server = TcpServer(options)
			assertEquals(server:GetPort(), options.port)
			assertEquals(server:GetHostName(), options.hostName)
			assertEquals(server:GetMaxBacklogSize(), options.backlogQueueSize)
			assertEquals(server:GetURL(), "tcp://0.0.0.0:123")

			server:StopListening()
		end)

		it("should register prototypes for all customizable event handlers", function()
			local expectedEventHandlers = {
				"TCP_CLIENT_CONNECTED",
				"TCP_CLIENT_DISCONNECTED",
				"TCP_CHUNK_RECEIVED",
				"TCP_WRITE_SUCCEEDED",
				"TCP_WRITE_FAILED",
				"TCP_SESSION_STARTED",
				"TCP_SESSION_ENDED",
				"TCP_SOCKET_ERROR",
				"TCP_CLIENT_READ_ERROR",
				"TCP_SERVER_STARTED",
				"TCP_SERVER_STOPPED",
			}

			local server = TcpServer()

			for _, eventID in ipairs(expectedEventHandlers) do
				assertEquals(type(server[eventID]), "function", "Should register listener for event " .. eventID)
			end

			server:StopListening()
		end)

		it("should start listening on the configured host and port immediately", function()
			local function codeUnderTest()
				local server = TcpServer()
				server:StopListening()
			end
			assertFunctionCalls(codeUnderTest, TcpServer, "StartListening")
		end)

		it("should have no active sessions before any client connects", function()
			local server = TcpServer()
			assertEquals(server:GetNumActiveSessions(), 0)
			server:StopListening()
		end)
	end)
end)
