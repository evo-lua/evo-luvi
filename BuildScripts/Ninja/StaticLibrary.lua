local ffi = require("ffi")
local uv = require("uv")

local ipairs = ipairs

local GnuCompilerCollectionRule = import("./BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("./BuildRules/BytecodeGenerationRule.lua")
local GnuArchiveCreationRule = import("./BuildRules/GnuArchiveCreationRule.lua")
local ExternalMakefileProjectRule = import("./BuildRules/ExternalMakefileProjectRule.lua")
local ExternalCMakeProjectRule = import("./BuildRules/ExternalCMakeProjectRule.lua")
local BuildTargetMixin = import("./BuildTargetMixin.lua")
local NinjaFile = import("../Ninja/NinjaFile.lua")

local path_basename = path.basename
local path_extname = path.extname
local path_join = path.join

local StaticLibrary = {
	fileExtension = (ffi.os == "Windows") and "lib" or "a"
}

function StaticLibrary:Construct(targetID)
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

StaticLibrary.__call = StaticLibrary.Construct
setmetatable(StaticLibrary, StaticLibrary)

mixin(StaticLibrary, BuildTargetMixin)

function StaticLibrary:GetBuildRules()
	return {
		compile = GnuCompilerCollectionRule(),
		bcsave = BytecodeGenerationRule(),
		archive = GnuArchiveCreationRule(),
		make = ExternalMakefileProjectRule(),
		cmake = ExternalCMakeProjectRule(),
		"compile",
		"bcsave",
		"archive",
		"make",
		"cmake",
	}
end

function StaticLibrary:CreateArchiveBuildEdge()

	if #self.sources == 0 then
		return
	end

	if #self.sources == 1 and ((path_basename(self.sources[1]) == "Makefile") or (path_basename(self.sources[1]) == "CMakeLists.txt")) then
		-- External project; we don't need to build it ourselves (no build edges are needed except for the final output)
		return
	end

	local buildCommandTokens = { "archive" }
	for _, sourceFile in ipairs(self.sources) do
		local objectFileName = path_basename(sourceFile) .. ".o"
		buildCommandTokens[#buildCommandTokens+1] = path_join("$builddir", self.targetID, objectFileName)
	end

	return path_join("$builddir", self.targetID, self:GetName()), buildCommandTokens, {}
end

function StaticLibrary:CreateCompilerBuildEdge(sourceFile)

	local extension = path_extname(sourceFile)
	local fileName = path_basename(sourceFile)
	if extension == ".c" then
		local dependencyTokens = { "compile", sourceFile }
		local overrides = {
			{
				name = "includes",
				declarationLine = "$includes",
			}
		}
		return path_join("$builddir", self.targetID, fileName .. ".o"), dependencyTokens, overrides
	elseif extension == ".lua" then
		local dependencyTokens = { "bcsave", sourceFile }
		local overrides = {	}

		return path_join("$builddir", self.targetID, fileName .. ".o"), dependencyTokens, overrides
	elseif fileName == "Makefile" then
		-- 	local MOVE_COMMAND = (ffi.os == "Windows") and "move" or "mv"
		-- 	local dependencyTokens = { "make", path_dirname(sourceFile), "&&", MOVE_COMMAND, "$out", path_join("$builddir", self.targetID) }
	-- 	local overrides = {	}

	-- 	ninjaFile:AddBuildEdge(path_join("$builddir", self.targetID, fileName), dependencyTokens, overrides)
		return
	elseif fileName == "CMakeLists.txt" then
		return
	else
		error(format("Failed to create build edge for input %s (unsupported file type: *%s)", sourceFile, extension), 0)
	end
end

function StaticLibrary:CreateBuildFile()
	local ninjaFile = NinjaFile()

	ninjaFile:AddVariable("builddir", ninjaFile.buildDirectory)

	ninjaFile:AddVariable("includes", self:GetIncludeFlags())
	ninjaFile:AddVariable("cwd", uv.cwd()) -- Useful for cd commands

	-- Rules should be iterated in order so that the file output is deterministic and testable
	local buildRules = self:GetBuildRules()
	for index, name in ipairs(buildRules) do
		local ruleInfo = buildRules[name]
		ninjaFile:AddRule(name, ruleInfo)
	end

	for _, sourceFile in ipairs(self.sources) do
		local name, dependencyTokens, variableOverrides = self:CreateCompilerBuildEdge(sourceFile)
		-- External projects are built using their own build mechanism, so we don't need to track intermediate (object) files
		if name and dependencyTokens and variableOverrides then
			ninjaFile:AddBuildEdge(name, dependencyTokens, variableOverrides)
		end
	end

	local path, buildCommandTokens, overrides = self:CreateArchiveBuildEdge()
	if path and buildCommandTokens and overrides then
		-- External projects should provide their own build mechanism, so we don't need to create the archive manually
		ninjaFile:AddBuildEdge(path, buildCommandTokens, overrides)
	end

	return ninjaFile
end

function StaticLibrary:GetName()
	if self.fileExtension == "lib" then
		return self.targetID .. "." .. self.fileExtension
	end

	return "lib" .. self.targetID .. "." .. self.fileExtension
end

return StaticLibrary