describe("runtime", function()
	local runtime = require("runtime")

	describe("version", function()
		it("should include a semantic version string", function()
			-- Technically git describe adds more information in between releases, but it's still "semver-like" enough
			assertEquals(type(runtime.version), "string")

			local expectedVersionStringPattern = "(v%d+%.%d+%.%d+.*)" --vMAJOR.MINOR.PATCH-optionalGitDescribeSuffix
			local versionString = string.match(runtime.version, expectedVersionStringPattern)

			assertEquals(type(versionString), "string")
		end)
	end)

	describe("signals", function()
		it("should be exported even if there are no dereferenced signal handlers", function()
			assertEquals(type(runtime.signals), "table")
		end)

		it("should store the dereferenced SIGPIPE handler when one is required", function()
			local uv = require("uv")
			-- This is a no-op on Windows
			if not uv.constants.SIGPIPE then
				return
			end

			local sigpipeHandler = runtime.signals.SIGPIPE
			assertEquals(type(sigpipeHandler), "userdata")
		end)
	end)

	describe("libraries", function()
		it("should export the version of all embedded libraries", function()
			local expectedLibraries = {
				"regex",
				"llhttp",
				"miniz",
				"ssl",
				"lpeg",
				"zlib",
				"libuv",
			}

			for index, libraryName in ipairs(expectedLibraries) do
				local exportedVersionString = runtime.libraries[libraryName]
				-- Since both the format and method of exporting varies for each library, that's all we can assert here...
				assertEquals(type(exportedVersionString), "string")
			end
		end)
	end)
end)
