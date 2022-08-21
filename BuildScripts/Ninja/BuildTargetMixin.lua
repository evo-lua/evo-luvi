local BuildTargetMixin = {
	includeDirectories = {},
	sources = {},
	dependencies = {},
}

local GCC_INCLUDE_FLAG = "-I"

function BuildTargetMixin:AddIncludeDirectory(directoryPath)
	self.includeDirectories[#self.includeDirectories+1] = directoryPath
end

function BuildTargetMixin:AddFiles(sourceFilePaths)
	for _, sourceFilePath in ipairs(sourceFilePaths) do
		self.sources[#self.sources+1] = sourceFilePath
	end
end

function BuildTargetMixin:GetIncludeFlags()
	local includeFlags = ""
	for _, includeDir in ipairs(self.includeDirectories) do
		includeFlags = includeFlags .. GCC_INCLUDE_FLAG .. includeDir .. " "
	end
	return includeFlags
end

function BuildTargetMixin:AddDependency(targetID)
	self.dependencies[targetID] = true
end

return BuildTargetMixin