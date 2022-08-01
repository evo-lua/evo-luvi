describe("Scenario", function()
	local function createNoOpScenario()
		return C_Testing.Scenario("Do nothing")
	end

	local function createMultiAssertionScenario()
		local scenario = C_Testing.Scenario("Multiple assertions (some failing)")

		local someValue = 0

		scenario:GIVEN("Some preconditions are true")
		scenario:WHEN("I run the test code")
		scenario:THEN("The post-conditions hold true")

		function scenario:OnRun()
			someValue = 42
		end

		function scenario:OnEvaluate()
			-- Mixing standard and nonstandard assertions here, with and without descriptions, to ensure all combinations work
			assert(someValue == 42)
			assert(someValue == 42, "Some value is set to 42")
			assertEquals(someValue, 43)
			assertEquals(someValue, 43, "Some value is set to 43")
			assert(someValue == 44, "Some value is set to 44")
		end

		return scenario
	end

	local function getNoOpScenarioOverviewText()
		-- Human-readable overview should indicate no handlers were registered
		local expectedOverviewText = "\n" -- To offset from the previous content (sub-optimal...)

		expectedOverviewText = expectedOverviewText .. "\t" -- To highlight the keywords visually
		expectedOverviewText = expectedOverviewText
			.. transform.cyan("Scenario: ")
			.. transform.white("Do nothing")
			.. "\n\n"
		expectedOverviewText = expectedOverviewText
			.. "\t"
			.. transform.cyan("GIVEN")
			.. "\t"
			.. transform.white("(no preconditions)")
			.. "\n"
		expectedOverviewText = expectedOverviewText
			.. "\t"
			.. transform.cyan("WHEN")
			.. "\t"
			.. transform.white("(no code to execute)")
			.. "\n"
		expectedOverviewText = expectedOverviewText
			.. "\t"
			.. transform.cyan("THEN")
			.. "\t"
			.. transform.white("(no postconditions)")
			.. "\n"
		return expectedOverviewText
	end

	local function getMultiAssertionsScenarioOverviewText()
		local expectedOverviewText = "\n" -- To offset from the previous content (sub-optimal...)
		expectedOverviewText = expectedOverviewText .. "\t" -- To highlight the keywords visually
		expectedOverviewText = expectedOverviewText
			.. transform.cyan("Scenario: ")
			.. transform.white("Multiple assertions (some failing)")
			.. "\n\n"
		expectedOverviewText = expectedOverviewText
			.. "\t"
			.. transform.cyan("GIVEN")
			.. "\t"
			.. transform.white("(no preconditions)")
			.. "\n"
		expectedOverviewText = expectedOverviewText
			.. "\t"
			.. transform.cyan("WHEN")
			.. "\t"
			.. transform.white("I run the test code")
			.. "\n"
		expectedOverviewText = expectedOverviewText
			.. "\t"
			.. transform.cyan("THEN")
			.. "\t"
			.. transform.white("The post-conditions hold true")
			.. "\n"
		return expectedOverviewText
	end

	local function getMultiAssertionsScenarioResultsText()
		local green = transform.green
		local red = transform.red
		local bold = transform.bold

		local expectedResultsText = "\t\t" .. green("✓") .. " (no description)\n"
		expectedResultsText = expectedResultsText .. "\t\t" .. green("✓") .. " Some value is set to 42\n"
		expectedResultsText = expectedResultsText
			.. "\t\t"
			.. red("✗")
			.. " "
			.. bold("42")
			.. " is not "
			.. bold("43")
			.. "\n"
		expectedResultsText = expectedResultsText .. "\t\t" .. red("✗") .. " Some value is set to 43\n"
		expectedResultsText = expectedResultsText .. "\t\t" .. red("✗") .. " Some value is set to 44\n"
		return expectedResultsText
	end

	describe("Construct", function()
		it("should initialize a new scenario with the given name", function()
			local scenario = createNoOpScenario()
			assertEquals(scenario:GetName(), "Do nothing")
		end)
	end)

	describe("Run", function()
		it("should display the full report text when a scenario without assertions is run", function()
			local scenario = createNoOpScenario()
			local expectedOverviewText = getNoOpScenarioOverviewText()
			local fauxConsole = C_Testing.CreateFauxConsole()
			assertEquals(fauxConsole.read(), "", "Should not have printed anything before the scenario was run")

			local expectedResultsText = ""
			scenario:Run(fauxConsole)
			local expectedSummaryText = transform.yellow("Warning: Nothing to assert (technically passing...)")
			local expectedOutput = expectedOverviewText .. expectedResultsText .. "\n" .. expectedSummaryText .. "\n"
			assertEquals(fauxConsole.read(), expectedOutput)
		end)

		it("should call the default event handlers when a scenario is run", function()
			local scenario = C_Testing.Scenario("Event handlers are called when a scenario is run")

			local numSetupExecutions = 0
			local numTestExecutions = 0
			local numEvaluationExecutions = 0
			local numCleanupExecutions = 0

			scenario.someValue = 42

			function scenario:OnSetup()
				numSetupExecutions = numSetupExecutions + 1
				assertEquals(self.someValue, 42, "Parameter self should be passed to OnSetup")
			end

			function scenario:OnRun()
				numTestExecutions = numTestExecutions + 1
				assertEquals(self.someValue, 42, "Parameter self should be passed to OnRun")
			end

			function scenario:OnEvaluate()
				numEvaluationExecutions = numEvaluationExecutions + 1
				assertEquals(self.someValue, 42, "Parameter self should be passed to OnEvaluate")
			end

			function scenario:OnCleanup()
				numCleanupExecutions = numCleanupExecutions + 1
				assertEquals(self.someValue, 42, "Parameter self should be passed to OnCleanup")
			end

			assertEquals(numSetupExecutions, 0, "Should not call the OnSetup handler before the scenario was run")
			assertEquals(numTestExecutions, 0, "Should not call the OnRun handler before the scenario was run")
			assertEquals(
				numEvaluationExecutions,
				0,
				"Should not call the OnEvaluate handler before the scenario was run"
			)
			assertEquals(numCleanupExecutions, 0, "Should not call the OnCleanup handler before the scenario was run")

			scenario:Run()

			assertEquals(numSetupExecutions, 1, "Should call the OnSetup handler when the scenario is run")
			assertEquals(numTestExecutions, 1, "Should call the OnRun handler when the scenario is run")
			assertEquals(numEvaluationExecutions, 1, "Should call the OnEvaluate handler when the scenario is run")
			assertEquals(numCleanupExecutions, 1, "Should call the OnCleanup handler when the scenario is run")

			scenario:Run()

			assertEquals(numSetupExecutions, 2, "Should call the OnSetup handler again when the scenario is run twice")
			assertEquals(numTestExecutions, 2, "Should call the OnRun handler again when the scenario is run twice")
			assertEquals(
				numEvaluationExecutions,
				2,
				"Should call the OnEvaluate handler again when the scenario is run twice"
			)
			assertEquals(
				numCleanupExecutions,
				2,
				"Should call the OnCleanup handler again when the scenario is run twice"
			)
		end)

		it(
			"should display the full report text when a scenario with both passing and failing assertions is run",
			function()
				local scenario = createMultiAssertionScenario()
				local expectedResultsText = getMultiAssertionsScenarioResultsText()

				local fauxConsole = C_Testing.CreateFauxConsole()
				assertEquals(fauxConsole.read(), "", "Should not have printed anything before the scenario was run")

				scenario:Run(fauxConsole)

				local expectedOverviewText = getMultiAssertionsScenarioOverviewText()
				local expectedSummaryText = transform.brightRedBackground("3 FAILED assertions")
				local expectedOutput = expectedOverviewText
					.. "\n"
					.. expectedResultsText
					.. "\n"
					.. expectedSummaryText
					.. "\n"
				assertEquals(fauxConsole.read(), expectedOutput)
				fauxConsole.clear()
			end
		)
	end)

	describe("HasFailed", function()
		it("should return false if no assertions have been added", function()
			local scenario = createNoOpScenario()
			assertFalse(scenario:HasFailed())
		end)

		it("should return false if assertions have been added, but the scenario hasn't yet run", function()
			local scenario = createMultiAssertionScenario()
			assertFalse(scenario:HasFailed())
		end)

		it("should return true if some assertions have failed after the scenario was run", function()
			local scenario = createMultiAssertionScenario()
			scenario:Run()
			assertTrue(scenario:HasFailed())
		end)
	end)

	describe("GetNumFailedAssertions", function()
		it("should return zero if no assertions have been added", function()
			local scenario = createNoOpScenario()
			assertEquals(scenario:GetNumFailedAssertions(), 0)
		end)

		it("should return zero if assertions have been added, but the scenario hasn't yet run", function()
			local scenario = createMultiAssertionScenario()
			assertEquals(scenario:GetNumFailedAssertions(), 0)
		end)

		it("should return the number of failed assertions if a scenario has been run", function()
			local scenario = createMultiAssertionScenario()
			scenario:Run()
			assertEquals(
				scenario:GetNumFailedAssertions(),
				3,
				"Should return the number of failed assertions after the scenario was run"
			)
		end)
	end)

	describe("GetOverviewText", function()
		it("should return a string representation of the scenario in a standardized format", function()
			local scenario = createNoOpScenario()
			local expectedOverviewText = getNoOpScenarioOverviewText()
			assertEquals(scenario:GetOverviewText(), expectedOverviewText)

			expectedOverviewText = getMultiAssertionsScenarioOverviewText()
			scenario = createMultiAssertionScenario()
			assertEquals(
				scenario:GetOverviewText(),
				expectedOverviewText,
				"Should return a string representation of the scenario in a standardized format"
			)
		end)
	end)

	describe("GetResultsText", function()
		it("should return an empty string if no assertions have been added", function()
			local scenario = createNoOpScenario()
			local expectedResultsText = ""
			assertEquals(scenario:GetResultsText(), expectedResultsText)
		end)

		it(
			"should return the evaluation results if a scenario with both failing and passing assertions was run",
			function()
				local expectedResultsText = getMultiAssertionsScenarioResultsText()
				local scenario = createMultiAssertionScenario()
				scenario:Run()
				assertEquals(scenario:GetResultsText(), expectedResultsText)
			end
		)
	end)

	describe("GetSummaryText", function()
		it("should return a warning instead of the summary if no assertions have been added", function()
			local scenario = createNoOpScenario()
			local expectedSummaryText = transform.yellow("Warning: Nothing to assert (technically passing...)")
			assertEquals(scenario:GetSummaryText(), expectedSummaryText)
		end)

		it(
			"should return the number of failed assertions if a scenario with failing assertions has been run",
			function()
				local scenario = createMultiAssertionScenario()
				scenario:Run()
				local expectedSummaryText = transform.brightRedBackground("3 FAILED assertions")
				assertEquals(scenario:GetSummaryText(), expectedSummaryText)
			end
		)
	end)
end)
