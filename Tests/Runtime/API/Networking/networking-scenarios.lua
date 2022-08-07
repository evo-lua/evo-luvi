local testSuite = C_Testing.TestSuite("Networking API")

local listOfScenarioFilesToLoad = {
	"./tcp-echo.lua",
	"./tcp-sigpipe.lua",
	-- "./http-hello-world.lua",
}

testSuite:AddScenarios(listOfScenarioFilesToLoad)

return testSuite
