local ffi = require("ffi")

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

	local includeFlags = ""
	for _, includeDir in ipairs(self.includeDirectories) do
		includeFlags = includeFlags .. GCC_INCLUDE_FLAG .. includeDir .. " "
	end
	ninjaFile:AddVariable("include_dirs", includeFlags)

	local compileCommandRule = {
		{ name = "command", "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "-o", "$out" },
		{ name = "description", "Compiling", "$out" },
		{ name = "depfile", "$out.d" },
		{ name = "deps", "gcc" },
	}
		ninjaFile:AddRule("compile", compileCommandRule)

	local bytecodeGenerationCommandRule = {
		{ name = "command", "luajit", "-b", "$in", "$out", },
		{ name = "description", "Generating optimized bytecode", "$out" },
		{ name = "deps", "luajit" },
	}
	ninjaFile:AddRule("bcsave", bytecodeGenerationCommandRule) -- Utilizes jit.bcsave

	for _, sourceFile in ipairs(self.sources) do
		local extension = path.extname(sourceFile)
		local fileName = path.basename(sourceFile)
		if extension == ".c" then
			local dependencyTokens = { "compile", fileName }
			local overrides = {
				{
					name = "includes",
					declarationLine = "-Iinclude_dir",
				}
			}

			ninjaFile:AddBuildEdge(fileName .. ".o", dependencyTokens, overrides)
		elseif extension == ".lua" then
			local dependencyTokens = { "bcsave", fileName }
			local overrides = {	}

			ninjaFile:AddBuildEdge(fileName .. ".o", dependencyTokens, overrides)
		else
			error(format("Cannot generate object files for sources of type %s (only C and Lua files are currently supported)", extension), 0)
		end
	end

	return ninjaFile
end

return StaticLibrary