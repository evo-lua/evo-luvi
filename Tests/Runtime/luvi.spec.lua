describe("luvi", function()
	local luvi = require("luvi")

	describe("version", function()
		it("should include a semantic version string", function()
			-- Technically git describe adds more information in between releases, but it's still "semver-like" enough
			assertEquals(type(luvi.version), "string")

			local expectedVersionStringPattern = "(v%d+%.%d+%.%d+.*)" --vMAJOR.MINOR.PATCH-optionalGitDescribeSuffix
			local versionString = string.match(luvi.version, expectedVersionStringPattern)

			assertEquals(type(versionString), "string")
		end)
	end)

	describe("signals", function()
		it("should be exported even if there are no dereferenced signal handlers", function()
			assertEquals(type(luvi.signals), "table")
		end)

		it("should store the dereferenced SIGPIPE handler when one is required", function()
			local uv = require("uv")
			-- This is a no-op on Windows
			if not uv.constants.SIGPIPE then
				return
			end

			local sigpipeHandler = luvi.signals.SIGPIPE
			assertEquals(type(sigpipeHandler), "userdata")
		end)
	end)
end)
