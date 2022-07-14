-- evo builtins
local describe = _G.describe
local it = _G.it
local import = _G.import
local assertEquals = _G.assertEquals
local assertFalse = _G.assertFalse

local luvi = require("luvi")
local LuviAppBundle = import("../../src/lua/luvibundle.lua")


describe("luvi", function()

	describe("LuviAppBundle", function()

		describe("buildBundle", function() end)
		describe("makeBundle", function() end)

		describe("RunContainedApp", function()

			it("should use the default entry point if none was passed", function()
				local expectedDefaultEntryPoint = _G.DEFAULT_USER_SCRIPT_ENTRY_POINT
				local bundle = LuviAppBundle.RunContainedApp({})
				assertEquals(bundle.mainPath, expectedDefaultEntryPoint)
			end)

			it("should raise an error if no bundle paths were passed", function()
				local success, errorMessage = pcall(LuviAppBundle.RunContainedApp)
				assertFalse(success)
				assertEquals(errorMessage, "Usage: RunContainedApp(bundlePaths : table, mainPath : string?, args : table?)")
			end)

			it("should store the passed file paths", function()
				-- Not sure WHY they need to be stored, but oh well...
				local files = {} -- Can't add files here or it will attempt to load them from disk...
				local bundle = LuviAppBundle.RunContainedApp(files)
				assertEquals(tostring(bundle.paths), tostring(files)) -- stringify to always check the table reference, not contents
			end)

			-- TBD: Can this be streamlined? Seems like a pretty strong side effect
			it("should store the most-recently loaded bundle in the luvi module", function()
				local appBundle = LuviAppBundle.RunContainedApp({ }, "something.lua")
				assertEquals(luvi.bundle, appBundle)
			end)

			-- it("should store the most recently-loaded bundle properties in the global environment", function()
			-- 	-- TBD Should it really do this?

			-- 	-- Important: The file needs to actually exist (for now... needs refactoring to allow easier testing)
			-- 	LuviAppBundle.RunContainedApp({ "src/lua/"}, "luvibundle.lua", { "something.lua" })

			-- 	local uv = require("uv")
			-- 	-- TODO This seems super fragile. Needs a proper API that can be mocked
			-- 	assertEquals(_G.USER_SCRIPT_FILE, "something.lua")
			-- 	assertEquals(_G.USER_SCRIPT_PATH, path.join(uv.cwd(), "main.lua"))
			-- 	assertEquals(_G.USER_SCRIPT_ROOT, uv.cwd())
			-- end)

			it("should export the CLI arguments array into the global environment", function()
				-- Whether or not this SHOULD really be done is a different question...
				assertEquals(_G.args, nil)

				local cliArguments = { "something" }
				-- Important: The file needs to actually exist (for now... needs refactoring to allow easier testing)
				LuviAppBundle.RunContainedApp({ "src/lua/"}, "init.lua", cliArguments)
				assertEquals(_G.args, cliArguments)
			end)

			it("should preload the builtin primitives", function()
				local cliArguments = { "something" }

				package.preload.v8_string = nil
				package.preload.virtual_file_system = nil

				assertEquals(package.preload.v8_string, nil)
				assertEquals(package.preload.virtual_file_system, nil)
				-- Important: The file needs to actually exist (for now... needs refactoring to allow easier testing)
				LuviAppBundle.RunContainedApp({ "src/lua/"}, "init.lua", cliArguments)

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
				LuviAppBundle.RunContainedApp({ "src/lua/"}, "init.lua")

				assertEquals(type(_G.dump), "function")
				assertEquals(type(_G.import), "function")
				assertEquals(type(_G.path), "table")
			end)

		end)
	end)

end)