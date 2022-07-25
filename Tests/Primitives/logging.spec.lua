describe("logging", function()
	local logging = require("logging")

	it("should export global aliases for all syslog-level logging functions", function()
		local standardLogLevels = {
			"EVENT",
			"TEST",
			"DEBUG",
			"INFO",
			"NOTICE",
			"WARNING",
			"ERROR",
			"CRITICAL",
			"ALERT",
			"EMERGENCY",
		}
		for _, logLevel in ipairs(standardLogLevels) do
			assertEquals(_G[logLevel], logging[string.lower(logLevel)])
			assertEquals(type(_G[logLevel]), "function")
		end
	end)
end)
