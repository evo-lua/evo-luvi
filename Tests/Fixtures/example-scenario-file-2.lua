local scenario = C_Testing.Scenario("Asserting some more stuff")

function scenario:OnEvaluate()
	assert(1 == 1, "Some description")
end

return scenario
