local ffi = require("ffi")
local uv = require("uv")

local GnuCompilerCollectionRule = import("./BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("./BuildRules/BytecodeGenerationRule.lua")

local path_basename = path.basename
local path_extname = path.extname
local path_dirname = path.dirname
local path_join = path.join

local GCC_INCLUDE_FLAG = "-I"

local NinjaFile = import("../Ninja/NinjaFile.lua")

local StaticLibrary = {
	fileExtension = (ffi.os == "Windows") and "lib" or "a"
}

function StaticLibrary:Construct(name)
	local instance = {
		includeDirectories = {},
		sources = {},
		name = name,
	}

	instance.__index = self
	setmetatable(instance, instance)

	return instance
end

StaticLibrary.__call = StaticLibrary.Construct
setmetatable(StaticLibrary, StaticLibrary)

function StaticLibrary:AddIncludeDirectory(directoryPath)
	self.includeDirectories[#self.includeDirectories+1] = directoryPath
end

function StaticLibrary:AddFiles(sourceFilePaths)
	for _, sourceFilePath in ipairs(sourceFilePaths) do
		self.sources[#self.sources+1] = sourceFilePath
	end
end

function StaticLibrary:CreateBuildFile()
	local ninjaFile = NinjaFile()

	ninjaFile:AddVariable("builddir", ninjaFile.buildDirectory)

	ninjaFile:AddVariable("include_dirs", self:GetIncludeFlags())
	ninjaFile:AddVariable("cwd", uv.cwd()) -- Useful for cd commands

	local compileCommandRule = GnuCompilerCollectionRule()
	ninjaFile:AddRule("compile", compileCommandRule)

	local bytecodeGenerationCommandRule = BytecodeGenerationRule()
	ninjaFile:AddRule("bcsave", bytecodeGenerationCommandRule) -- Utilizes jit.bcsave, hence the name

	local archiveCommandRule = {
		{ name = "command", "ar", "crs", "$out", "$in"},
		{ name = "description", "Creating archive", "$out" },
	}
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
					declarationLine = "$include_dirs",
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

function StaticLibrary:GetIncludeFlags()
	local includeFlags = ""
	for _, includeDir in ipairs(self.includeDirectories) do
		includeFlags = includeFlags .. GCC_INCLUDE_FLAG .. includeDir .. " "
	end
	return includeFlags
end

return StaticLibrary