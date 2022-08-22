local StaticLibrary = import("../../BuildScripts/Ninja/StaticLibrary.lua")
local GnuCompilerCollectionRule = import("../../BuildScripts/Ninja/BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("../../BuildScripts/Ninja/BuildRules/BytecodeGenerationRule.lua")
local GnuArchiveCreationRule = import("../../BuildScripts/Ninja/BuildRules/GnuArchiveCreationRule.lua")
local ExternalMakefileProjectRule = import("../../BuildScripts/Ninja/BuildRules/ExternalMakefileProjectRule.lua")
local ExternalCMakeProjectRule = import("../../BuildScripts/Ninja/BuildRules/ExternalCMakeProjectRule.lua")

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

	describe("GetBuildRules", function()
		it("should return a set of build rules for the default GCC/LuaJIT toolchain", function()
			local target = StaticLibrary("mylib")

			local expectedBuildRules = {
				compile = GnuCompilerCollectionRule(),
				bcsave = BytecodeGenerationRule(),
				archive = GnuArchiveCreationRule(),
				make = ExternalMakefileProjectRule(),
				cmake = ExternalCMakeProjectRule(),
			}
			assertEquals(target:GetBuildRules(), expectedBuildRules)
		end)
	end)

	describe("CreateBuildFile", function() end)
end)