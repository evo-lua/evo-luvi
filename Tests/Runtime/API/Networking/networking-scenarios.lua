local testSuite = C_Testing.TestSuite("Networking API")

local listOfScenarioFilesToLoad = {
	"./tcp-echo.lua",
}

testSuite:AddScenarios(listOfScenarioFilesToLoad)

return testSuite
