local ffi = require("ffi")

local BuildTargetMixin = import("./BuildTargetMixin.lua")
local NinjaFile = import("../Ninja/NinjaFile.lua")

local Executable = {
	fileExtension = (ffi.os == "Windows") and "exe" or ""
}

function Executable:Construct(name)
	local instance = {
		includeDirectories = {},
		sources = {},
		name = name,
	}

	instance.__index = self
	setmetatable(instance, instance)

	return instance
end

Executable.__call = Executable.Construct
setmetatable(Executable, Executable)

mixin(Executable, BuildTargetMixin)

function Executable:CreateBuildFile()
	local ninjaFile = NinjaFile()

	for targetID, hasNinjaBuildFile in ipairs(self.dependencies) do
		if not hasNinjaBuildFile then
			error(format("Cannot include target %s (not a ninja build file)", targetID))
		end

		ninjaFile:AddInclude(targetID)
	end

	return ninjaFile
end

return Executable