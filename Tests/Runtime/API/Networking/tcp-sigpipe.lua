local uv = require("uv")

if not uv.constants.SIGPIPE then
	-- The constant is set if and only if the signal exists (i.e., Unix-like platforms); others don't need to care about handling it
	local jit = require("jit")
	TEST(transform.yellow(format("Skipped test: TCP server receives SIGPIPE (Not relevant to platform %s)", jit.os)))
	return
end

local scenario = C_Testing.Scenario("TCP server receives SIGPIPE")
local TcpServer = C_Networking.TcpServer

scenario:GIVEN("A TCP echo server is listening on localhost")
scenario:WHEN("It receives a SIGPIPE error signal from an external source")
scenario:THEN("The server should not crash and continue to operate normally")

local hasSentSignal = false

function scenario:OnSetup()
	local serverOptions = {
		port = 9123,
		hostName = "127.0.0.1",
	}
	self.server = TcpServer(serverOptions)
end

function scenario:OnRun()
	local currentThread = coroutine.running()

	local server = self.server

	local function setTimeout(timeout, callback)
		local timer = uv.new_timer()
		timer:start(timeout, 0, function()
			timer:stop()
			timer:close()
			callback()
		end)
		return timer
	end

	local currentProcessID = uv.os_getpid()
	local currentParentProcessID = uv.os_getppid()
	TEST(format("This TCP echo server is running in process %d", currentProcessID))
	TEST(format("Parent process: %d", currentParentProcessID))

	setTimeout(5, function()
		TEST("Sending SIGPIPE to current process (pretend it came from the OS...)")
		os.execute("ps -A")
		local killCommandString = "kill -" .. uv.constants.SIGPIPE .. " " .. currentProcessID
		TEST("Executing command: " .. killCommandString)
		os.execute(killCommandString)
		hasSentSignal = true
	end)

	setTimeout(100, function()
		TEST("No SIGPIPE error signal received yet; shutting down echo server...")
		server:StopListening()
		coroutine.resume(currentThread)
	end)

	-- Hand off control to libuv to let async requests complete
	coroutine.yield()
end

function scenario:OnEvaluate()
	assertTrue(hasSentSignal, "The server should have received the SIGPIPE error signal")
end

return scenario
