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
		targetID = targetID,
		includeDirectories = {},
		sources = {},
		dependencies = {},
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

local table_concat = table.concat
local path_join = path.join

-- TODO tests
function Executable:CreateArchiveBuildEdge() -- TODO DRY
	local buildCommandTokens = { "archive" }
	for _, sourceFile in ipairs(self.sources) do
		local objectFileName = path_basename(sourceFile) .. ".o"
		buildCommandTokens[#buildCommandTokens+1] = path_join("$builddir", self.targetID, objectFileName)
	end

	return path_join("$builddir", self.targetID, self:GetName()), buildCommandTokens, {}
end
	-- TODO tests
function Executable:CreateBuildFile()
	local ninjaFile = NinjaFile()

	local dependencyObjectNames = {}
	dependencyObjectNames[#dependencyObjectNames+1] = "compile"
	for index, sourceFilePath in ipairs(self.sources) do
		-- ninjaFile:AddInclude(sourceFilePath .. ".o")
	end

	for index, target in ipairs(self.dependencies) do
		dependencyObjectNames[#dependencyObjectNames+1] = target:GetName()
	end

	-- local libsString = table_concat()
	-- ninjaFile:AddBuildEdge(path_join("$builddir", self:GetName()), dependencyObjectNames, { name = "libs", dependentLine  = "-L" .. }) -- tbd link libs override?

	return ninjaFile
end

function Executable:GetName()
	if self.fileExtension == "" then
		return self.targetID
	end

	return self.targetID .. "." .. self.fileExtension
end

return Executable