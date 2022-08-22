local Executable = import("../../BuildScripts/Ninja/Executable.lua")

local GnuCompilerCollectionRule = import("../../BuildScripts/Ninja/BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("../../BuildScripts/Ninja/BuildRules/BytecodeGenerationRule.lua")
local GnuLinkageEditorRule = import("../../BuildScripts/Ninja/BuildRules/GnuLinkageEditorRule.lua")
local ExternalMakefileProjectRule = import("../../BuildScripts/Ninja/BuildRules/ExternalMakefileProjectRule.lua")
local ExternalCMakeProjectRule = import("../../BuildScripts/Ninja/BuildRules/ExternalCMakeProjectRule.lua")

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

	describe("GetBuildRules", function()
		it("should return a set of build rules for the default GCC/LuaJIT toolchain", function()
			local target = Executable("myapp")

			local expectedBuildRules = {
				compile = GnuCompilerCollectionRule(),
				bcsave = BytecodeGenerationRule(),
				archive = GnuLinkageEditorRule(),
				make = ExternalMakefileProjectRule(),
				cmake = ExternalCMakeProjectRule(),
			}
			assertEquals(target:GetBuildRules(), expectedBuildRules)
		end)
	end)

	describe("GetBuildEdges", function() end)
	describe("CreateBuildFile", function() end)
end)