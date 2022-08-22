local ffi = require("ffi")

local GnuCompilerCollectionRule = import("./BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("./BuildRules/BytecodeGenerationRule.lua")
local GnuLinkageEditorRule = import("./BuildRules/GnuLinkageEditorRule.lua")
local ExternalMakefileProjectRule = import("./BuildRules/ExternalMakefileProjectRule.lua")
local ExternalCMakeProjectRule = import("./BuildRules/ExternalCMakeProjectRule.lua")
local BuildTargetMixin = import("./BuildTargetMixin.lua")
local NinjaFile = import("../Ninja/NinjaFile.lua")

local Executable = {
	fileExtension = (ffi.os == "Windows") and "exe" or ""
}

function Executable:Construct(targetID)
	local instance = {
		includeDirectories = {},
		sources = {},
		targetID = targetID,
	}

	instance.__index = self
	setmetatable(instance, instance)

	return instance
end

Executable.__call = Executable.Construct
setmetatable(Executable, Executable)

mixin(Executable, BuildTargetMixin)

function Executable:GetBuildRules()
	return {
		compile = GnuCompilerCollectionRule(),
		bcsave = BytecodeGenerationRule(),
		link = GnuLinkageEditorRule(),
		make = ExternalMakefileProjectRule(),
		cmake = ExternalCMakeProjectRule(),
		"compile",
		"bcsave",
		"link",
		"make",
		"cmake",
	}
end

-- TODO tests
function Executable:CreateBuildFile()
	local ninjaFile = NinjaFile()

	for index, targetID in ipairs(self.dependencies) do
		ninjaFile:AddInclude(targetID)
	end
	-- Rest NYI

	return ninjaFile
end

function Executable:GetName()
	if self.fileExtension == "" then
		return self.targetID
	end

	return self.targetID .. "." .. self.fileExtension
end

return Executable