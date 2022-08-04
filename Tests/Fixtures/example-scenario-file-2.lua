local scenario = C_Testing.Scenario("Asserting some more stuff")

function scenario:OnEvaluate()
	assert(1 == 1, "Some description")
end

function scenario:SetDisplayedTime()
	-- No-op to avoid fluctuations in the actual runtime breaking the tests
end

return scenario
