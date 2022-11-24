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
end)
