describe("TestSuite", function()
	local emptyTestSuite = C_Testing.TestSuite("TestSuite with no scenarios")

	local function createFailingTestSuite()
		local failingTestSuiteWithOneScenario = C_Testing.TestSuite("TestSuite with multiple failing assertions")
		local scenario = C_Testing.Scenario("NOOP scenario")

		function scenario:OnEvaluate()
			assert(1 == 1, "NOOP assertion #1")
			assert(42 == 0, "FAILED assertion #1")
			assert(1234 == 12345, "FAILED assertion #2")
		end

		function scenario:SetDisplayedTime()
			-- No-op to avoid fluctuations in the actual runtime breaking the tests
		end

		failingTestSuiteWithOneScenario:AddScenario(scenario)
		return failingTestSuiteWithOneScenario
	end

	local function createPassingTestSuite()
		local testSuite = C_Testing.TestSuite("TestSuite with multiple passing assertions")

		assertEquals(testSuite:GetNumScenarios(), 0, "Should return zero if no scenarios have been added")

		local scenario = C_Testing.Scenario("NOOP scenario")

		function scenario:OnEvaluate()
			assert(1 == 1, "NOOP assertion #1")
			assert(42 == 42, "NOOP assertion #2")
			assert(1234 == 1234, "NOOP assertion #3")
		end

		function scenario:SetDisplayedTime()
			-- No-op to avoid fluctuations in the actual runtime breaking the tests
		end

		testSuite:AddScenario(scenario)

		return testSuite
	end

	local function createMultiScenarioTestSuite()
		local testSuite = C_Testing.TestSuite("Adding multiple scenarios at once")

		local listOfScenarioFilesToLoad = {
			"../../Fixtures/example-scenario-file-1.lua",
			"../../Fixtures/example-scenario-file-2.lua",
		}

		testSuite:AddScenarios(listOfScenarioFilesToLoad)

		return testSuite
	end

	describe("GetNumScenarios", function()
		it("should return zero if no scenarios have been added", function()
			assertEquals(emptyTestSuite:GetNumScenarios(), 0)
		end)

		it("should return one if a single scenario has been added", function()
			local failingTestSuiteWithOneScenario = createFailingTestSuite()
			assertEquals(
				failingTestSuiteWithOneScenario:GetNumScenarios(),
				1,
				"Should return one if a single scenarios has been added"
			)
		end)
	end)

	describe("ReportSummary", function()
		it(
			"should display a summary text indicating no scenarios have been added if test suite wasn't yet run",
			function()
				local fauxConsole = C_Testing.CreateFauxConsole()
				emptyTestSuite:ReportSummary(fauxConsole)

				local expectedConsoleOutput = C_Testing.TestSuite.HORIZONTAL_LINE_SEPARATOR .. "\n\n"
				expectedConsoleOutput = expectedConsoleOutput
					.. transform.cyan("Test Suite: ")
					.. transform.white("TestSuite with no scenarios")
					.. "\n\n"
				expectedConsoleOutput = expectedConsoleOutput
					.. transform.yellow("Warning: No scenarios to run (technically passing...)")
					.. "\n"
				assertEquals(fauxConsole.read(), expectedConsoleOutput, "")
			end
		)
	end)

	describe("HasFailedScenarios", function()
		it("should return false if no scenarios have been added", function()
			assertFalse(emptyTestSuite:HasFailedScenarios())
		end)

		it("should return true if at least one scenario has failed", function()
			local failingTestSuiteWithOneScenario = createFailingTestSuite()
			failingTestSuiteWithOneScenario:Run()
			assertTrue(failingTestSuiteWithOneScenario:HasFailedScenarios())
		end)

		it("should return false if no scenarios have failed", function()
			local testSuite = createPassingTestSuite()
			assertFalse(testSuite:HasFailedScenarios())
		end)
	end)

	describe("Run", function()
		it("should return false if at least one assertion has failed", function()
			local testSuite = C_Testing.TestSuite("Failing test runner generates EXIT_FAILURE code")

			local failingScenario = C_Testing.Scenario("Scenario with failed assertion")
			function failingScenario:OnEvaluate()
				assert(1 == 0, "Should always fail and raise an error in the process")
			end
			testSuite:AddScenario(failingScenario)
			assertFalse(testSuite:Run())
		end)

		it("should return true if not a single assertion has failed", function()
			local testSuite = C_Testing.TestSuite("Passing test runner generates EXIT_SUCCESS code")

			local passingScenario = C_Testing.Scenario("Scenario with passing assertion")
			function passingScenario:OnEvaluate()
				assert(1 == 1, "Should always succeed and NOT raise an error in the process")
			end
			testSuite:AddScenario(passingScenario)
			assertTrue(testSuite:Run())
		end)

		it(
			"should display a summary text indicating no assertions have failed when a passing test suite is run",
			function()
				local testSuite = createPassingTestSuite()
				local fauxConsole = C_Testing.CreateFauxConsole()
				assertEquals(fauxConsole.read(), "")
				testSuite:Run(fauxConsole)
				local expectedConsoleOutput = C_Testing.TestSuite.HORIZONTAL_LINE_SEPARATOR .. "\n\n"
				-- The 0.00ms is kinda risky here, but it's probably safe to assume the three NOOPS won't take any significant time...
				expectedConsoleOutput = expectedConsoleOutput
					.. transform.cyan("Test Suite: ")
					.. transform.white("TestSuite with multiple passing assertions")
					.. "\n\n"
				expectedConsoleOutput = expectedConsoleOutput
					.. "\t"
					.. transform.green("✓")
					.. " "
					.. "NOOP scenario: 3 passing (0.00 ms)"
					.. "\n\n"
				expectedConsoleOutput = expectedConsoleOutput
					.. transform.green("All scenarios completed successfully!")
					.. "\n"
				assertEquals(fauxConsole.read(), expectedConsoleOutput)
			end
		)

		it("should display a summary text indicating the failed assertions when a failing test suite is run", function()
			local failingTestSuiteWithOneScenario = createFailingTestSuite()
			local fauxConsole = C_Testing.CreateFauxConsole()

			assertEquals(fauxConsole.read(), "", "Should not display anything before the test suite was run")
			failingTestSuiteWithOneScenario:Run(fauxConsole)

			local expectedConsoleOutput = C_Testing.TestSuite.HORIZONTAL_LINE_SEPARATOR .. "\n\n"
			-- The 0.00ms is kinda risky here, but it's probably safe to assume the three NOOPS won't take any significant time...
			expectedConsoleOutput = expectedConsoleOutput
				.. transform.cyan("Test Suite: ")
				.. transform.white("TestSuite with multiple failing assertions")
				.. "\n\n"
			expectedConsoleOutput = expectedConsoleOutput
				.. "\t"
				.. transform.red("✗")
				.. " "
				.. "NOOP scenario: "
				.. transform.brightRedBackground("2 FAILED assertions")
				.. "\n\n"
			expectedConsoleOutput = expectedConsoleOutput .. transform.brightRedBackground("1 scenario failed!") .. "\n"
			assertEquals(fauxConsole.read(), expectedConsoleOutput)
		end)

		it("should display the expected result after loading and running multiple passing scenario files", function()
			local testSuite = createMultiScenarioTestSuite()
			local fauxConsole = C_Testing.CreateFauxConsole()

			testSuite:Run(fauxConsole)

			local expectedConsoleOutput = C_Testing.TestSuite.HORIZONTAL_LINE_SEPARATOR .. "\n\n"
			expectedConsoleOutput = expectedConsoleOutput
				.. transform.cyan("Test Suite: ")
				.. transform.white("Adding multiple scenarios at once")
				.. "\n\n"
			expectedConsoleOutput = expectedConsoleOutput
				.. "\t"
				.. transform.green("✓")
				.. " "
				.. "Asserting some stuff: 1 passing (0.00 ms)"
				.. "\n"
			expectedConsoleOutput = expectedConsoleOutput
				.. "\t"
				.. transform.green("✓")
				.. " "
				.. "Asserting some more stuff: 1 passing (0.00 ms)"
				.. "\n\n"
			expectedConsoleOutput = expectedConsoleOutput
				.. transform.green("All scenarios completed successfully!")
				.. "\n"

			assertEquals(fauxConsole.read(), expectedConsoleOutput)
		end)
	end)
end)
