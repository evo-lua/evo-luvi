-- These aren't proper unit tests, but they should still make sure the snippets included in the docs actually work
local exampleScripts = C_FileSystem.ReadDirectory(path.join("Tests", "Examples"))

local function testSnippetFile(fileName)
	local fullPath = path.join("Examples", fileName)

	DEBUG("Running example: " .. fileName)

	describe("Snippet: " .. fileName, function()
		it("should run without errors", function()
			import(fullPath)
		end)
	end)
end

for fileName in pairs(exampleScripts) do
	testSnippetFile(fileName)
end
