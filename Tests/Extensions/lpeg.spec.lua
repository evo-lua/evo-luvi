local lpeg = require("lpeg")
local re = require("re")

describe("lpeg", function()
	local exportedFunctions = {
		"B",
		"C",
		"Carg",
		"Cb",
		"Cc",
		"Cf",
		"Cg",
		"Cmt",
		"Cp",
		"Cs",
		"Ct",
		"P",
		"R",
		"S",
		"V",
		"locale",
		"match",
		"pcode",
		"ptree",
		"setmaxstack",
		"type",
		"utfR",
	}

	it("should export all LPEG functions", function()
		for _, functionName in ipairs(exportedFunctions) do
			local exportedFunction = lpeg[functionName]
			assertEquals(type(exportedFunction), "function", "Should export function " .. functionName)
		end
	end)

	describe("version", function()
		it("should contain the embedded LPEG version in semver format", function()
			-- A match here indicates the prefix is no longer present
			local firstMatchedCharacterIndex, lastMatchedCharacterIndex = string.find(lpeg.version, "%d+.%d+.%d+")
			assertEquals(firstMatchedCharacterIndex, 1)
			assertEquals(lastMatchedCharacterIndex, string.len(lpeg.version))

			assertEquals(type(string.match(lpeg.version, "%d+.%d+.%d+")), "string")
		end)

		it("should be exported to the runtime options", function()
			-- This probably needs a rework, but for now it will just live here
			local displayedLpegVersion = require("luvi").options.lpeg
			local embeddedLpegVersion = lpeg.version
			assertEquals(displayedLpegVersion, embeddedLpegVersion)
		end)
	end)
end)

describe("re", function()
	local exportedFunctions = {
		"compile",
		"find",
		"gsub",
		"match",
		"updatelocale",
	}

	it("should export all LPEG-RE functions", function()
		for _, functionName in ipairs(exportedFunctions) do
			local exportedFunction = re[functionName]
			assertEquals(type(exportedFunction), "function", "Should export function " .. functionName)
		end
	end)
end)
