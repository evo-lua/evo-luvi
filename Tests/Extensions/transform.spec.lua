local supportedTerminalColors = {
	"black",
	"blackBackground",
	"bold",
	"brightRedBackground",
	"cyan",
	"gray",
	"green",
	"greenBackground",
	"red",
	"underline",
	"white",
	"whiteBackground",
	"yellow",
}

describe("transform", function()
	it("should be set to apply color codes by default", function()
		assertTrue(transform.ENABLE_TEXT_TRANSFORMATIONS)
	end)

	it("should support applying all valid color codes if text transformations are enabled", function()
		for _, color in ipairs(supportedTerminalColors) do
			local text = "hello"
			local coloredText = transform[color](text)
			assertEquals(
				coloredText,
				transform.START_SEQUENCE .. transform.colorCodes[color] .. text .. transform.RESET_SEQUENCE
			)
		end
	end)

	it("should not modify the input if text transformations are disabled", function()
		transform.disable()

		for _, color in ipairs(supportedTerminalColors) do
			local text = "hello"
			local coloredText = transform[color](text)
			assertEquals(coloredText, text)
		end

		transform.enable()
	end)

	it("should raise an error if a non-string value is passed", function()
		local ffi = require("ffi")

		local invalidValues = {
			42,
			{},
			function() end,
			ffi.new("uint8_t"),
		}
		for _, color in ipairs(supportedTerminalColors) do
			for _, invalidValue in ipairs(invalidValues) do
				assertThrows(function()
					transform[color](invalidValue)
				end, "Usage: transform." .. color .. "(text : string)")
			end
		end
	end)

	describe("enable", function()
		it("should enable the injection of color codes if they've previously been disabled", function()
			transform.ENABLE_TEXT_TRANSFORMATIONS = false
			assertFalse(transform.ENABLE_TEXT_TRANSFORMATIONS)

			transform.enable()

			assertTrue(transform.ENABLE_TEXT_TRANSFORMATIONS)
		end)
	end)

	describe("disable", function()
		it("should disable the injection of color codes if they've previously been enabled", function()
			assertTrue(transform.ENABLE_TEXT_TRANSFORMATIONS)

			transform.disable()
			assertFalse(transform.ENABLE_TEXT_TRANSFORMATIONS)

			-- Restore the default setting
			transform.ENABLE_TEXT_TRANSFORMATIONS = true
		end)
	end)
end)
