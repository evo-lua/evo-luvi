local HttpRequest = C_Networking.HttpRequest
local IncrementalHttpRequestParser = C_Networking.IncrementalHttpRequestParser

describe("IncrementalHttpRequestParser", function()
	describe("Construct", function() end)

	describe("ParseNextChunk", function() end)

	describe("GetCurrentRequest", function()
		it("should return an empty placeholder request when no chunks have been processed", function()
			local defaultRequest = HttpRequest()
			local parser = IncrementalHttpRequestParser()
			assertEquals(parser:GetCurrentRequest(), defaultRequest)
		end)
	end)

	describe("ResetInternalState", function() end)

	describe("IsRequestFinished", function() end)

	describe("Flush", function() end)
end)
