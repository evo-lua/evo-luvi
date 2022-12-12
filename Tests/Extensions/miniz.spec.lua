local miniz = require("miniz")

describe("miniz", function()
	local exportedFunctions = {
		"adler32",
		"compress",
		"crc32",
		"deflate",
		"inflate",
		"new_deflator",
		"new_inflator",
		"new_reader",
		"new_writer",
		"uncompress",
		"version",
	}

	it("should export all miniz functions", function()
		for _, functionName in ipairs(exportedFunctions) do
			local exportedFunction = miniz[functionName]
			assertEquals(type(exportedFunction), "function", "Should export function " .. functionName)
		end
	end)

	describe("version", function()
		it("should return the embedded miniz version in semver format", function()
			local embeddedMinizVersion = miniz.version()
			local firstMatchedCharacterIndex, lastMatchedCharacterIndex =
				string.find(embeddedMinizVersion, "%d+.%d+.%d+")

			assertEquals(firstMatchedCharacterIndex, 1)
			assertEquals(lastMatchedCharacterIndex, string.len(embeddedMinizVersion))
			assertEquals(type(string.match(embeddedMinizVersion, "%d+.%d+.%d+")), "string")
		end)

		it("should be stored in the runtime library", function()
			-- This probably needs a rework, but for now it will just live here
			local displayedMinizVersion = require("runtime").libraries.miniz
			local embeddedMinizVersion = miniz.version()
			assertEquals(displayedMinizVersion, embeddedMinizVersion)
		end)
	end)
end)
