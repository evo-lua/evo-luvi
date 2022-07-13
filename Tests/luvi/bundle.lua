-- evo builtins
local describe = _G.describe
local it = _G.it
local import = _G.import
local assertEquals = _G.assertEquals
local assertFalse = _G.assertFalse

local luvibundle = import("../../src/lua/luvibundle.lua")

describe("luvi", function()

	describe("bundle", function()

		describe("buildBundle", function() end)
		describe("makeBundle", function() end)

		describe("commonBundle", function()

			it("should use the default entry point if none was passed", function()
				local expectedDefaultEntryPoint = _G.DEFAULT_USER_SCRIPT_ENTRY_POINT
				local bundle = luvibundle.commonBundle({})
				assertEquals(bundle.mainPath, expectedDefaultEntryPoint)
			end)

			it("should raise an error if no bundle paths were passed", function()
				local success, errorMessage = pcall(luvibundle.commonBundle)
				assertFalse(success)
				assertEquals(errorMessage, "Usage: commonBundle (bundlePaths : table, mainPath : string?, args : table?)")
			end)

			it("should store the passed file paths", function()
				-- Not sure WHY they need to be stored, but oh well...
				local files = {} -- Can't add files here or it will attempt to load them from disk...
				local bundle = luvibundle.commonBundle(files)
				assertEquals(tostring(bundle.paths), tostring(files)) -- stringify to always check the table reference, not contents
			end)

			it("should export the CLI arguments array into the global environment", function()
				-- Whether or not this SHOULD really be done is a different question...
				assertEquals(_G.args, nil)

				local cliArguments = { "something" }
				-- Important: The file needs to actually exist (for now... needs refactoring to allow easier testing)
				luvibundle.commonBundle({ "src/lua/"}, "init.lua", cliArguments)
				assertEquals(_G.args, cliArguments)
			end)

			it("should preload the builtin primitives", function()
				local cliArguments = { "something" }

				package.preload.v8_string = nil
				package.preload.virtual_file_system = nil

				assertEquals(package.preload.v8_string, nil)
				assertEquals(package.preload.virtual_file_system, nil)
				-- Important: The file needs to actually exist (for now... needs refactoring to allow easier testing)
				luvibundle.commonBundle({ "src/lua/"}, "init.lua", cliArguments)

				assertEquals(type(package.preload.v8_string), "table")
				assertEquals(type(package.preload.virtual_file_system), "table")
			end)

			it("should export the builtin extension globals", function()
				_G.dump = nil
				_G.path = nil
				_G.import = nil

				assertEquals(_G.dump, nil)
				assertEquals(_G.path, nil)
				assertEquals(_G.import, nil)

				-- Important: The file needs to actually exist (for now... needs refactoring to allow easier testing)
				luvibundle.commonBundle({ "src/lua/"}, "init.lua")

				assertEquals(type(_G.dump), "function")
				assertEquals(type(_G.import), "function")
				assertEquals(type(_G.path), "table")
			end)

		end)
	end)

end)