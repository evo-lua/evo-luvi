local ffi = require("ffi")
local path_basename = path.basename
local path_extname = path.extname

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

function StaticLibrary:AddBuildTargets(sourceFilePaths)
	for _, sourceFilePath in ipairs(sourceFilePaths) do
		self.sources[#self.sources+1] = sourceFilePath
	end
end

function StaticLibrary:CreateBuildFile()
	local ninjaFile = NinjaFile()

	ninjaFile:AddVariable("builddir", ninjaFile.buildDirectory)

	local includeFlags = ""
	for _, includeDir in ipairs(self.includeDirectories) do
		includeFlags = includeFlags .. GCC_INCLUDE_FLAG .. includeDir .. " "
	end
	ninjaFile:AddVariable("include_dirs", includeFlags)

	local compileCommandRule = {
		{ name = "command", "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "$include_dirs", "-o", "$out" },
		{ name = "description", "Compiling", "$in" },
		{ name = "depfile", "$out.d" },
		{ name = "deps", "gcc" },
	}
	ninjaFile:AddRule("compile", compileCommandRule)

	local bytecodeGenerationCommandRule = {
		{ name = "command", "luajit", "-b", "$in", "$out", },
		{ name = "description", "Saving optimized bytecode for", "$in" },
		{ name = "deps", "luajit" },
	}
	ninjaFile:AddRule("bcsave", bytecodeGenerationCommandRule) -- Utilizes jit.bcsave

	local archiveCommandRule = {
		{ name = "command", "rm", "-f", "$out", "&&", "ar", "crs", "$out", "$in"},
		{ name = "description", "Creating archive", "$out" },
	}
	ninjaFile:AddRule("archive", archiveCommandRule)

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
			ninjaFile:AddBuildEdge("$builddir/" .. self.name .. "/" .. fileName .. ".o", dependencyTokens, overrides)
		elseif extension == ".lua" then
			local dependencyTokens = { "bcsave", sourceFile }
			local overrides = {	}

			ninjaFile:AddBuildEdge("$builddir/" .. self.name .. "/" .. fileName .. ".o", dependencyTokens, overrides)
		else
			error(format("Cannot generate object files for sources of type %s (only C and Lua files are currently supported)", extension), 0)
		end
	end

	local buildCommandTokens = { "archive" }
	for _, sourceFile in ipairs(self.sources) do
		local objectFileName = path_basename(sourceFile) .. ".o"
		buildCommandTokens[#buildCommandTokens+1] = "$builddir/" .. self.name .. "/" .. objectFileName
	end

	local libraryName = (ffi.os == "Windows") and (self.name .. ".dll") or ("lib" .. self.name .. ".a")
	ninjaFile:AddBuildEdge("$builddir/" .. self.name .. "/" .. libraryName, buildCommandTokens)

	return ninjaFile
end

return StaticLibrary