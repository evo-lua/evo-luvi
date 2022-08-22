local ffi = require("ffi")
local uv = require("uv")

local GnuCompilerCollectionRule = import("./BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("./BuildRules/BytecodeGenerationRule.lua")
local GnuArchiveCreationRule = import("./BuildRules/GnuArchiveCreationRule.lua")
local BuildTargetMixin = import("./BuildTargetMixin.lua")
local NinjaFile = import("../Ninja/NinjaFile.lua")

local path_basename = path.basename
local path_extname = path.extname
local path_join = path.join

local StaticLibrary = {
	fileExtension = (ffi.os == "Windows") and "lib" or "a"
}

function StaticLibrary:Construct(name)
	local instance = {
		name = name,
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
	}
end

function StaticLibrary:CreateBuildFile()
	local ninjaFile = NinjaFile()

	ninjaFile:AddVariable("builddir", ninjaFile.buildDirectory)

	ninjaFile:AddVariable("include_flags", self:GetIncludeFlags())
	ninjaFile:AddVariable("cwd", uv.cwd()) -- Useful for cd commands

	local compileCommandRule = GnuCompilerCollectionRule()
	ninjaFile:AddRule("compile", compileCommandRule)

	local bytecodeGenerationCommandRule = BytecodeGenerationRule()
	ninjaFile:AddRule("bcsave", bytecodeGenerationCommandRule) -- Utilizes jit.bcsave, hence the name

	local archiveCommandRule = GnuArchiveCreationRule()
	ninjaFile:AddRule("archive", archiveCommandRule)

	-- local makeCommandRule = {
	-- 	{ name = "command", "cd", "$in", "&&", "make", "&&", "cd", "&&", "$cwd"},
	-- 	{ name = "description", "Running Makefile build in directory", "$out" },
	-- }
	-- ninjaFile:AddRule("make", makeCommandRule)

	for _, sourceFile in ipairs(self.sources) do
		local extension = path_extname(sourceFile)
		local fileName = path_basename(sourceFile)
		if extension == ".c" then
			local dependencyTokens = { "compile", sourceFile }
			local overrides = {
				{
					name = "includes",
					declarationLine = "$include_flags",
				}
			}
			ninjaFile:AddBuildEdge(path_join("$builddir", self.name, fileName .. ".o"), dependencyTokens, overrides)
		elseif extension == ".lua" then
			local dependencyTokens = { "bcsave", sourceFile }
			local overrides = {	}

			local libraryName = (ffi.os == "Windows") and (self.name .. ".lib") or ("lib" .. self.name .. ".a") -- TODO DRY
			ninjaFile:AddBuildEdge(path_join("$builddir", self.name, libraryName), dependencyTokens, overrides)
		-- elseif fileName == "Makefile" then
		-- 	local MOVE_COMMAND = (ffi.os == "Windows") and "move" or "mv"
		-- 	local dependencyTokens = { "make", path_dirname(sourceFile), "&&", MOVE_COMMAND, "$out", path_join("$builddir", self.name) }
		-- 	local overrides = {	}

		-- 	ninjaFile:AddBuildEdge(path_join("$builddir", self.name, fileName), dependencyTokens, overrides)
		else
			error(format("Cannot generate object files for sources of type %s (only C and Lua files are currently supported)", extension), 0)
		end
	end

	local buildCommandTokens = { "archive" }
	for _, sourceFile in ipairs(self.sources) do
		local objectFileName = path_basename(sourceFile) .. ".o"
		buildCommandTokens[#buildCommandTokens+1] = path_join("$builddir", self.name, objectFileName)
	end

	local libraryName = (ffi.os == "Windows") and (self.name .. ".lib") or ("lib" .. self.name .. ".a") -- TODO DRY
	ninjaFile:AddBuildEdge(path_join("$builddir", self.name, libraryName), buildCommandTokens)

	return ninjaFile
end

function StaticLibrary:GetName()
	if self.fileExtension == "lib" then
		return self.name .. "." .. self.fileExtension
	end

	return "lib" .. self.name .. "." .. self.fileExtension
end

return StaticLibrary