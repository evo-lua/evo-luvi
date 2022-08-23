local BuildTargetMixin = {}

local GCC_INCLUDE_FLAG = "-I"

-- TODO Test
function BuildTargetMixin:AddIncludeDirectory(directoryPath)
	self.includeDirectories[#self.includeDirectories+1] = directoryPath
end

-- TODO Test
function BuildTargetMixin:AddFile(sourceFilePath)
	self.sources[#self.sources+1] = sourceFilePath
end

-- TODO Test
function BuildTargetMixin:AddFiles(sourceFilePaths)
	for _, sourceFilePath in ipairs(sourceFilePaths) do
		self:AddFile(sourceFilePath)
	end
end

-- TODO Test
function BuildTargetMixin:GetIncludeFlags()
	local includeFlags = ""
	for _, includeDir in ipairs(self.includeDirectories) do
		includeFlags = includeFlags .. GCC_INCLUDE_FLAG .. includeDir .. " "
	end
	return includeFlags
end

-- TODO Test
function BuildTargetMixin:AddDependency(targetID)
	self.dependencies[#self.dependencies+1] = targetID
end

return BuildTargetMixin