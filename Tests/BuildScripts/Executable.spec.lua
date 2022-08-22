local Executable = import("../../BuildScripts/Ninja/Executable.lua")

local ffi = require("ffi")
local isWindows = (ffi.os == "Windows")

describe("Executable", function()

	describe("GetName", function()
		it("should return an executable name following the OS conventions", function()

			local target = Executable("myapp")
			if isWindows then
				assertEquals(target:GetName(), "myapp.exe")
			else
				assertEquals(target:GetName(), "myapp")
			end
		end)
	end)

	describe("CreateBuildFile", function() end)
end)