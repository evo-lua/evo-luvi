local testSuite = C_Testing.TestSuite("Networking API")

local listOfScenarioFilesToLoad = {
	"./tcp-echo.lua",
	"./tcp-sigpipe.lua",
	"./tcp-server-triggers-eof-event.lua",
	"./tcp-client-triggers-eof-event.lua",
	"./tcp-server-handles-backpressure.lua",
	"./tcp-client-handles-backpressure.lua",
}

testSuite:AddScenarios(listOfScenarioFilesToLoad)

return testSuite
