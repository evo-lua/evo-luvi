describe("uv", function()
	describe("errors", function()
		it("should export human-readable error messages for all libuv error constants", function()
			local expectedErrorConstants = {
				"ECONNRESET",
				"EADDRINUSE",
			}

			local uv = require("uv")
			local expectedNumErrorConstants = 80 -- Not great to hardcode this, as it will probably change in the future?

			assertEquals(table.count(uv.errors), expectedNumErrorConstants)

			for _, errorConstant in ipairs(expectedErrorConstants) do
				assertEquals(type(errorConstant), "string")

				local friendlyErrorMessage = uv.errors[errorConstant]
				assertEquals(type(friendlyErrorMessage), "string")
			end
		end)
	end)

	describe("strerror", function()
		local uv = require("uv")
		it("should return UV_UNKNOWN if an invalid error code was passed", function()
			assertEquals(uv.strerror(12345), uv.errors.UNKNOWN)
		end)

		it("should return the libuv error string if a valid error code was passed", function()
			assertEquals(uv.strerror("ECONNRESET"), "Connection reset by peer")
		end)
	end)
end)
