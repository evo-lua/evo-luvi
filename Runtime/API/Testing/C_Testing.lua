local C_Testing = {
	TestSuite = require("TestSuite"),
	Scenario = require("Scenario"),
}

function C_Testing.CreateFauxConsole()
	local tostring = tostring

	local fauxConsole = {
		stdoutBuffer = "",
	}

	-- Append string to the stdout buffer
	function fauxConsole.print(...)
		fauxConsole.stdoutBuffer = fauxConsole.stdoutBuffer .. tostring(... or "") .. "\n"
	end

	-- Clear the stdout buffer
	function fauxConsole.clear()
		fauxConsole.stdoutBuffer = ""
	end

	-- Return the contents of the stdout buffer
	function fauxConsole.read()
		return fauxConsole.stdoutBuffer
	end

	return fauxConsole
end

function C_Testing.CreateFauxTcpClient()
	local fauxTcpClient = {}

	function fauxTcpClient:read_start(onResultCallback)
		onResultCallback("ERROR")
	end

	function fauxTcpClient:getpeername()
		return {
			family = "virtual",
			ip = "127.0.0.1",
			port = 123,
		}
	end

	function fauxTcpClient:shutdown() end
	function fauxTcpClient:close() end

	return fauxTcpClient
end

function C_Testing.CreateUnitTestRunner(testCases)
	-- Crappy makeshift test runner... for now it will do
	local numTestsComplete = 0
	local numFailedTests = 0

	local string_rep = string.rep
	local print = print

	local bold = transform.bold

	local indent = 0
	local function indentText(text, ...)
		print(string_rep("  ", indent) .. text, ...)
	end

	local queuedSetupCode = nil
	local queuedTeardownCode = nil

	local function before(oneTimeSetupCode)
		queuedSetupCode = oneTimeSetupCode
	end

	local function after(oneTimeTeardownCode)
		queuedTeardownCode = oneTimeTeardownCode
	end

	local function describe(description, codeUnderTest)
		indentText(bold(description))
		indent = indent + 1

		codeUnderTest()

		numTestsComplete = numTestsComplete + 1
		indent = indent - 1

		if type(queuedTeardownCode) == "function" then
			-- Tests must have registered some teardown code that we should run
			TEST("Running one-time teardown code")
			queuedTeardownCode()
			queuedTeardownCode = nil
		end
	end

	local iconFail = transform.brightRed("✗")
	local iconSuccess = transform.green("✓")

	local function it(label, codeUnderTest)
		if type(queuedSetupCode) == "function" then
			-- Tests must have registered some setup code that we should run
			TEST("Running one-time setup code")
			queuedSetupCode()
			queuedSetupCode = nil
		end

		indent = indent + 1

		local success, errorMessage = pcall(codeUnderTest)
		local icon = success and iconSuccess or iconFail

		if not success then
			label = transform.brightRed(label)
		end
		indentText(icon .. " " .. label)

		if success then
			numTestsComplete = numTestsComplete + 1
		else
			ERROR(errorMessage)
			numFailedTests = numFailedTests + 1
		end

		indent = indent - 1
	end

	_G.describe = describe
	_G.it = it
	_G.before = before
	_G.after = after

	local uv = require("uv")

	local timeStart = uv.hrtime()

	for _, testFile in ipairs(testCases) do
		import(testFile)
	end

	local timeEnd = uv.hrtime()
	local durationInMilliseconds = (timeEnd - timeStart) / 10E6 -- ns (hrtime) to ms
	durationInMilliseconds = math.floor(durationInMilliseconds + 0.5)

	print()

	if numFailedTests > 1 then
		printf(transform.brightRedBackground("✗ %s tests FAILED (%s ms)"), numFailedTests, durationInMilliseconds)
	elseif numFailedTests == 1 then
		printf(transform.brightRedBackground("✗ %s test FAILED (%s ms)"), numFailedTests, durationInMilliseconds)
	elseif numTestsComplete > 1 then
		printf(transform.green("✓ %s tests complete (%s ms)"), numTestsComplete, durationInMilliseconds)
	else
		printf(transform.green("✓ %s test complete (%s ms)"), numTestsComplete, durationInMilliseconds)
	end

	os.exit(numFailedTests)
end

return C_Testing
