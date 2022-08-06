local uv = require("uv")

local format = string.format
local setmetatable = setmetatable
local print = print

local time = uv.hrtime

local NOOP_FUNCTION = function() end
local NANOSECONDS_PER_MILLISECOND = 10E5

local Scenario = {}

function Scenario:Construct(name)
	local instance = {
		name = name or "",
		runTimeInMilliseconds = 0,
		descriptions = {
			GIVEN = "",
			WHEN = "",
			THEN = "",
		},
		assertions = {},
	}

	instance.__index = Scenario
	setmetatable(instance, instance)

	return instance
end

Scenario.__call = Scenario.Construct
setmetatable(Scenario, Scenario)

-- These should be overridden by user scripts
Scenario.OnSetup = NOOP_FUNCTION
Scenario.OnRun = NOOP_FUNCTION
Scenario.OnEvaluate = NOOP_FUNCTION
Scenario.OnCleanup = NOOP_FUNCTION

function Scenario:GIVEN(description)
	if type(description) ~= "string" then
		return
	end

	self.descriptions.GIVEN = description
end

function Scenario:WHEN(description)
	if type(description) ~= "string" then
		return
	end

	self.descriptions.WHEN = description
end

function Scenario:THEN(description)
	if type(description) ~= "string" then
		return
	end

	self.descriptions.THEN = description
end

function Scenario:SetDisplayedTime(runTimeInMilliseconds)
	self.runTimeInMilliseconds = runTimeInMilliseconds
end

function Scenario:Run(console)
	local startTimeInNanoseconds = time()

	self:OnSetup()
	self:OnRun()

	local globalAssert = assert

	local silentAssert = function(condition, description)
		local isConditionTrue = condition

		description = description or "(no description)"

		local assertionDetails = {
			description = description,
			isSuccess = isConditionTrue,
		}
		self.assertions[#self.assertions + 1] = assertionDetails
	end

	_G.assert = silentAssert
	self:OnEvaluate()
	_G.assert = globalAssert

	local endTimeInNanoseconds = time()
	local runTimeInNanoseconds = (endTimeInNanoseconds - startTimeInNanoseconds)
	local runTimeInMilliseconds = runTimeInNanoseconds / NANOSECONDS_PER_MILLISECOND
	self:SetDisplayedTime(runTimeInMilliseconds)

	self:OnCleanup()

	self:OnReport(console)
end

function Scenario:ToString()
	local hasResults = self:GetResultsText() ~= ""

	return self:GetOverviewText()
		.. "\n"
		-- Displaying the number of assertions is pointless if there are none, but if any are present the summary needs more space
		.. self:GetResultsText()
		.. (hasResults and "\n" or "")
		.. self:GetSummaryText()
end

function Scenario:GetOverviewText()
	local displayText = ""

	local LINEBREAK = "\n"
	local INDENT = "\t"

	displayText = displayText .. LINEBREAK
	displayText = displayText .. INDENT .. transform.cyan("Scenario: ") .. transform.white(self.name) .. LINEBREAK
	displayText = displayText .. LINEBREAK

	local preconditionsText = (self.descriptions.GIVEN == "") and "(no preconditions)" or self.descriptions.GIVEN
	if self.OnSetup == NOOP_FUNCTION then
		preconditionsText = "(no preconditions)"
	end

	local scriptText = (self.descriptions.WHEN == "") and "(no code to execute)" or self.descriptions.WHEN
	if self.OnRun == NOOP_FUNCTION then
		scriptText = "(no code to execute)"
	end

	local postconditionsText = (self.descriptions.THEN == "") and "(no postconditions)" or self.descriptions.THEN
	if self.OnEvaluate == NOOP_FUNCTION then
		postconditionsText = "(no postconditions)"
	end

	displayText = displayText
		.. INDENT
		.. transform.cyan("GIVEN")
		.. INDENT
		.. transform.white(preconditionsText)
		.. LINEBREAK
	displayText = displayText .. INDENT .. transform.cyan("WHEN") .. INDENT .. transform.white(scriptText) .. LINEBREAK
	displayText = displayText
		.. INDENT
		.. transform.cyan("THEN")
		.. INDENT
		.. transform.white(postconditionsText)
		.. LINEBREAK

	return displayText
end

function Scenario:GetResultsText()
	local coloredResultsText = ""
	local failedAssertionCount = 0

	for assertionID, assertionDetails in ipairs(self.assertions) do
		local description = assertionDetails.description
		local isSuccess = assertionDetails.isSuccess

		local successIcon = transform.yellow("﹖")

		-- Explicitly checking here to avoid nil being interpreted as false
		if isSuccess == true then
			successIcon = transform.green("✓")
		end
		if isSuccess == false then
			successIcon = transform.red("✗")
			failedAssertionCount = failedAssertionCount + 1
		end

		coloredResultsText = coloredResultsText .. (format("\t\t%s %s", successIcon, description)) .. "\n"
	end

	return coloredResultsText
end

function Scenario:GetSummaryText()
	local totalAssertionCount = #self.assertions
	local failedAssertionCount = self:GetNumFailedAssertions()

	local coloredSummaryText
	if failedAssertionCount == 0 then
		coloredSummaryText =
			format("%s passing (%.0f ms)", totalAssertionCount - failedAssertionCount, self.runTimeInMilliseconds)
	end

	if failedAssertionCount > 0 then
		coloredSummaryText = transform.brightRedBackground(format("%s FAILED assertions", failedAssertionCount))
	end

	if failedAssertionCount == 1 then -- OCD
		coloredSummaryText = transform.brightRedBackground("1 FAILED assertion")
	end

	if totalAssertionCount == 0 then
		coloredSummaryText = transform.yellow("Warning: Nothing to assert (technically passing...)")
	end

	return coloredSummaryText
end

function Scenario:OnReport(console)
	local printFunction = console and console.print or print
	printFunction(self:ToString())
end

function Scenario:GetName()
	return self.name or ""
end

function Scenario:GetNumFailedAssertions()
	local failedAssertionCount = 0

	for assertionID, assertionDetails in ipairs(self.assertions) do
		local isSuccess = assertionDetails.isSuccess

		-- Explicitly checking here to avoid nil being interpreted as false
		if isSuccess == false then
			failedAssertionCount = failedAssertionCount + 1
		end
	end

	return failedAssertionCount
end

function Scenario:HasFailed()
	return self:GetNumFailedAssertions() > 0
end

return Scenario
