local llhttp = require("llhttp")

describe("llhttp", function()
	it("should be exported as a preloaded package", function()
		assertEquals(type(llhttp), "table")
	end)

	it("should export all of the llhttp-ffi API", function()
		local exportedApiSurface = {
			"llhttp_init",
			"llhttp_reset",
			"llhttp_settings_init",
			"llhttp_execute",
			"llhttp_finish",
			"llhttp_message_needs_eof",
			"llhttp_should_keep_alive",
			"llhttp_pause",
			"llhttp_resume",
			"llhttp_resume_after_upgrade",
			"llhttp_get_errno",
			"llhttp_get_error_reason",
			"llhttp_set_error_reason",
			"llhttp_get_error_pos",
			"llhttp_get_upgrade",
			"llhttp_errno_name",
			"llhttp_method_name",
			"llhttp_set_lenient_headers",
			"llhttp_set_lenient_chunked_length",
			"llhttp_set_lenient_keep_alive",
		}

		for _, functionName in ipairs(exportedApiSurface) do
			assertEquals(type(llhttp.bindings[functionName]), "cdata", "Should bind function " .. functionName)
		end
	end)
end)
