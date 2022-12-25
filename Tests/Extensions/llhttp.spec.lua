local llhttp = require("llhttp")
local ffi = require("ffi")


describe("llhttp", function()
	it("should be exported as a preloaded package", function()
		assertEquals(type(llhttp), "table")
	end)

	describe("bindings", function()
		it("should export all of the llhttp API", function()
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

		it("should export all of the llhttp-ffi API", function()
			local exportedApiSurface = {
				"llhttp_get_version_string",
				"llhttp_store_event",
				"stringbuffer_add_event",
			}

			for _, functionName in ipairs(exportedApiSurface) do
				assertEquals(type(llhttp.bindings[functionName]), "cdata", "Should bind function " .. functionName)
			end
		end)

		describe("llhttp_get_version_string", function()
			it("should return a semantic version string", function()
				local cVersionString = llhttp.bindings.llhttp_get_version_string()
				local luaVersionString = ffi.string(cVersionString)

				assertEquals(ffi.string(cVersionString), luaVersionString)
				local major, minor, patch =
					string.match(luaVersionString, "(%d+).(%d+).(%d+)")

				assertEquals(type(major), "string")
				assertEquals(type(minor), "string")
				assertEquals(type(patch), "string")
			end)
		end)

		describe("llhttp_get_max_url_length", function()
			it("should return a number (defined inside the FFI layer)", function()
				local maxLength = llhttp.bindings.llhttp_get_max_url_length()
				assertEquals(tonumber(maxLength), 256)
			end)
		end)

		describe("llhttp_get_max_header_key_length", function()
			it("should return a number (defined inside the FFI layer)", function()
				local maxLength = llhttp.bindings.llhttp_get_max_header_key_length()
				assertEquals(tonumber(maxLength), 256)
			end)
		end)

		describe("llhttp_get_max_header_value_length", function()
			it("should return a number (defined inside the FFI layer)", function()
				local maxLength = llhttp.bindings.llhttp_get_max_header_value_length()
				assertEquals(tonumber(maxLength), 256)
			end)
		end)


		describe("llhttp_get_max_header_count", function()
			it("should return a number (defined inside the FFI layer)", function()
				local maxLength = llhttp.bindings.llhttp_get_max_header_count()
				assertEquals(tonumber(maxLength), 256)
			end)
		end)


		describe("llhttp_get_max_body_length", function()
			it("should return a number (defined inside the FFI layer)", function()
				local maxLength = llhttp.bindings.llhttp_get_max_body_length()
				assertEquals(tonumber(maxLength), 256)
			end)
		end)
	-- llhttp_userdata_get_required_size
	-- llhttp_userdata_get_actual_size
	-- llhttp_userdata_message_fits_buffer

	-- llhttp_userdata_reset
	-- llhttp_userdata_is_message_complete
	-- llhttp_userdata_is_overflow_error
	-- llhttp_userdata_is_streaming_body
	-- llhttp_userdata_get_body_tempfile_path
	-- lhttp_userdata_is_buffering_body

	-- llhttp_userdata_get_max_url_size
	-- llhttp_userdata_get_max_reason_size
	-- llhttp_userdata_get_max_body_size
	-- llhttp_userdata_get_max_header_field_size
	-- llhttp_userdata_get_max_header_value_size
	-- llhttp_userdata_get_max_headers_array_size
	-- llhttp_userdata_debug_dump
	end)

	describe("initialize", function()
		it("should have no effect if the bindings are already initialized", function()
			-- The runtime already initialized them when assigning the static exports table
			-- But for the sake of argument, let's pretend it didn't and that this was the first time
			llhttp.initialize()
			-- Then this would be the second (actually, it's the third...) time, which should still be a no-op
			llhttp.initialize()
			-- No errors so far? Great... But the bindings should also still be available...
			assertEquals(type(llhttp.bindings), "cdata")
		end)
	end)

	describe("version", function()
		it("should return the embedded llhttp version in semver format", function()
			local embeddedVersion = llhttp.version()
			local firstMatchedCharacterIndex, lastMatchedCharacterIndex =
				string.find(embeddedVersion, "%d+.%d+.%d+")

			assertEquals(firstMatchedCharacterIndex, 1)
			assertEquals(lastMatchedCharacterIndex, string.len(embeddedVersion))
			assertEquals(type(string.match(embeddedVersion, "%d+.%d+.%d+")), "string")
		end)

		it("should be stored in the runtime library", function()
			-- This probably needs a rework, but for now it will just live here
			local displayedVersion = require("runtime").libraries.llhttp
			local embeddedVersion = llhttp.version()
			assertEquals(displayedVersion, embeddedVersion)
		end)
	end)

end)
