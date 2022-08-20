local DEFAULT_REQUIRED_VERSION = "1.11"
local DEFAULT_BUILD_DIRECTORY_NAME = "ninjabuild"

local NinjaFile = {
	requiredVersion = DEFAULT_REQUIRED_VERSION,
	buildDirectory = DEFAULT_BUILD_DIRECTORY_NAME,
	-- Untested (NYI)
	ruleDeclarations = {},
	buildEdges = {},
	variables = {},
	defaultTargets = {},
	subninjas = {},
	includes = {},
	pool = {},
}

NinjaFile.DEFAULT_REQUIRED_VERSION = DEFAULT_REQUIRED_VERSION
NinjaFile.DEFAULT_BUILD_DIRECTORY_NAME = DEFAULT_BUILD_DIRECTORY_NAME

function NinjaFile:Construct()
	local instance = {}

	instance.__index = self
	setmetatable(instance, instance)

	return instance
end

NinjaFile.__call = NinjaFile.Construct
setmetatable(NinjaFile, NinjaFile)

return NinjaFile