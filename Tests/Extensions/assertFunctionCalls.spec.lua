describe("assertFunctionCalls", function()
	local MyModule = {}

	function MyModule:DoSomething() end

	local function callsTargetFunctionOnce()
		MyModule:DoSomething()
	end

	local function callsTargetFunctionTwice()
		MyModule:DoSomething()
		MyModule:DoSomething()
	end

	local function neverCallsTargetFunction() end

	it(
		"should not raise an error if the code under test calls the target function the expected number of times",
		function()
			assertFunctionCalls(callsTargetFunctionTwice, MyModule, "DoSomething", 2)
		end
	)

	it("should raise an error if the target function is not called at all", function()
		local function shouldCallErrorHandler()
			assertFunctionCalls(neverCallsTargetFunction, MyModule, "DoSomething")
		end

		local success = pcall(shouldCallErrorHandler)
		assertFalse(success)
	end)

	it("should raise an error if the target function isn't called often enough", function()
		local function shouldCallErrorHandler()
			assertFunctionCalls(callsTargetFunctionOnce, MyModule, "DoSomething", 2)
		end

		local success = pcall(shouldCallErrorHandler)
		assertFalse(success)
	end)
end)
