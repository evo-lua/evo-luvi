local C_BuildTools = import("../../../../Runtime/API/BuildTools/C_BuildTools.lua")

local ffi = require("ffi")

describe("C_BuildTools", function()
	describe("GetStaticLibraryName", function()
		it("should return a standardized library name on all supported systems", function()
			local libraryBaseName = "awesome"

			-- LuaJIT docs: Can only be "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other"
			local expectedLibraryNamesPerOS = {
				["Windows"] = "awesome.lib",
				["Linux"] = "libawesome.a",
				["OSX"] = "libawesome.a",
				["BSD"] = "libawesome.a",
				["POSIX"] = "libawesome.a",
				["Other"] = "libawesome.a",
			}

			local standardizedLibraryName = C_BuildTools.GetStaticLibraryName(libraryBaseName)
			local expectedLibraryName = expectedLibraryNamesPerOS[ffi.os]
			assertEquals(standardizedLibraryName, expectedLibraryName)
		end)
	end)

	describe("GetSharedLibraryName", function()
		it("should return a standardized library name on all supported systems", function()
			local libraryBaseName = "awesome"

			-- LuaJIT docs: Can only be "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other"
			local expectedLibraryNamesPerOS = {
				["Windows"] = "awesome.dll",
				["Linux"] = "libawesome.so",
				["OSX"] = "libawesome.so",
				["BSD"] = "libawesome.so",
				["POSIX"] = "libawesome.so",
				["Other"] = "libawesome.so",
			}

			local standardizedLibraryName = C_BuildTools.GetSharedLibraryName(libraryBaseName)
			local expectedLibraryName = expectedLibraryNamesPerOS[ffi.os]
			assertEquals(standardizedLibraryName, expectedLibraryName)
		end)
	end)

	describe("GetExecutableName", function()
		it("should return a standardized executable name on all supported systems", function()
			local libraryBaseName = "notavirus"

			-- LuaJIT docs: Can only be "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other"
			local expectedLibraryNamesPerOS = {
				["Windows"] = "notavirus.exe",
				["Linux"] = "notavirus",
				["OSX"] = "notavirus",
				["BSD"] = "notavirus",
				["POSIX"] = "notavirus",
				["Other"] = "notavirus",
			}

			local standardizedLibraryName = C_BuildTools.GetExecutableName(libraryBaseName)
			local expectedLibraryName = expectedLibraryNamesPerOS[ffi.os]
			assertEquals(standardizedLibraryName, expectedLibraryName)
		end)
	end)
end)
