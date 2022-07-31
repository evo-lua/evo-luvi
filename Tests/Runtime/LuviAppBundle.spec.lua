local uv = require("uv")
local LuviAppBundle = import("../../Runtime/LuaEnvironment/LuviAppBundle.lua")

describe("LuviAppBundle", function()
	local appDir = path.join(uv.cwd(), "Tests", "Fixtures", "AppWithErrors")
	local zipAppPath = path.join(uv.cwd(), "Tests", "Fixtures", "myapp.zip")
	local appWithErrors = LuviAppBundle(appDir)

	describe("RunContainedApp", function()
		before(function()
			appWithErrors:CreateZipApp(zipAppPath)
			assert(uv.fs_stat(zipAppPath), "Failed to create temporary file: " .. zipAppPath)
		end)

		after(function()
			assert(uv.fs_unlink(zipAppPath), "Failed to remove temporary file " .. zipAppPath)
		end)

		it("should raise an error prefixed with the executable name if running a script from a zip app", function()
			local function codeUnderTest()
				local zipAppWithErrors = LuviAppBundle(zipAppPath)
				zipAppWithErrors:RunContainedApp({})
			end
			-- This should probably use "myapp" as the app name, but that's not currently possible since evo loads the tests
			local executableName = path.basename(uv.exepath())
			local expectedErrorMessage = executableName .. ":main.lua:1: whoops" -- Default Lua format (not great, but alas...)
			assertThrows(codeUnderTest, expectedErrorMessage)
		end)

		it("should raise an error prefixed with only the script name if running a script on disk", function()
			local function codeUnderTest()
				appWithErrors:RunContainedApp({})
			end
			local expectedErrorMessage = "main.lua:1: whoops" -- Default Lua format (not great, but alas...)
			assertThrows(codeUnderTest, expectedErrorMessage)
		end)

		it("should not run the main thread in a coroutine", function()
			local currentThread, isMainThread = coroutine.running()
			assertEquals(coroutine.status(currentThread), "running")
			assertEquals(type(currentThread), "thread")
			-- If running on the main thread, we can't yield to pause until I/O is ready... but at least stack traces aren't eaten
			assertTrue(isMainThread)
		end)
	end)
end)
