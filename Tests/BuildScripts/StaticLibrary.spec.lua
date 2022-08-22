local StaticLibrary = import("../../BuildScripts/Ninja/StaticLibrary.lua")

local ffi = require("ffi")
local isWindows = (ffi.os == "Windows")

describe("StaticLibrary", function()
	describe("GetName", function()
		it("should return an executable name following the OS conventions", function()

			local target = StaticLibrary("hello")
			if isWindows then
				assertEquals(target:GetName(), "hello.lib")
			else
				assertEquals(target:GetName(), "libhello.a")
			end
		end)
	end)

	describe("CreateBuildFile", function() end)
end)