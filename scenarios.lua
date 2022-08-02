-- Acceptance tests (below) use a more verbose format and should only be used for use case scenarios
local testSuites = {
	"Tests/Runtime/API/Networking/networking-scenarios.lua",
}

for _, filePath in pairs(testSuites) do
	local testSuite = import(filePath)
	-- For CI pipelines and scripts, ensure the return code indicates EXIT_FAILURE if at least one assertion has failed
	assert(testSuite:Run(), "Assertion failure in test suite " .. filePath)
end
