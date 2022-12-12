local regex = require("regex")

describe("regex", function()
	local exportedFunctions = {
		"config",
		"count",
		"find",
		"flags",
		"gmatch",
		"gsub",
		"maketables",
		"match",
		"new",
		"split",
		"version",
	}

	it("should export all PCRE2 functions", function()
		for _, functionName in ipairs(exportedFunctions) do
			local exportedFunction = regex[functionName]
			assertEquals(type(exportedFunction), "function", "Should export function " .. functionName)
		end
	end)

	describe("version", function()
		-- This format isn't exactly semver, but it's close enough to not care (so there's no need to modify it)
		it("should contain the embedded PCRE2 version in semver + date format", function()
			local embeddedPcreVersion = regex.version()
			local PCRE_VERSION_STRING_PATTERN = "%d+.%d+ %d+-%d+-%d+" -- e.g., 10.4 2022-04-14 (it's just what they use, I guess)
			local firstMatchedCharacterIndex, lastMatchedCharacterIndex =
				string.find(embeddedPcreVersion, PCRE_VERSION_STRING_PATTERN)

			assertEquals(firstMatchedCharacterIndex, 1)
			assertEquals(lastMatchedCharacterIndex, string.len(embeddedPcreVersion))

			local pcreVersionString = string.match(embeddedPcreVersion, PCRE_VERSION_STRING_PATTERN)
			assertEquals(pcreVersionString, embeddedPcreVersion)
		end)

		it("should be stored in the runtime library", function()
			-- This probably needs a rework, but for now it will just live here
			local displayedPcreVersion = require("runtime").libraries.regex
			local embeddedPcreVersion = regex.version()
			local embeddedLrexlibVersion = regex._VERSION

			-- It might help to display both versions, similar to how it's handled for lua-openssl and openssl itself
			local fullPcreVersionString = embeddedPcreVersion .. ", " .. embeddedLrexlibVersion
			assertEquals(displayedPcreVersion, fullPcreVersionString)
		end)
	end)

	local subj = "We go to school"
	local patt = "(\\w+)\\s+(\\w+)"
	local repl = "%2 %1"

	describe("find", function()
		it("should return all captures and indices if the pattern matches the subject", function()
			local from, to, cap1, cap2 = regex.find(subj, patt)
			assertEquals(from, 1)
			assertEquals(to, 5)
			assertEquals(cap1, "We")
			assertEquals(cap2, "go")
		end)
	end)

	describe("gsub", function()
		it("should return the altered subject if both search and replacement patterns match", function()
			local result = regex.gsub(subj, patt, repl)
			assertEquals(result, "go We school to")
		end)
	end)

	describe("gmatch", function()
		it("should return an iterator for all matches if the pattern matches the subject", function()
			local string = "The red frog sits on the blue box in the green well."
			local colors = {}
			for color in regex.gmatch(string, "(red|blue|green)") do
				colors[#colors + 1] = color
			end
			assertEquals(#colors, 3)
		end)
	end)
end)
