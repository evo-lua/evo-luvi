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

	for index, targetID in ipairs(self.dependencies) do
		ninjaFile:AddInclude(targetID)
	end

	return ninjaFile
end

function Executable:GetName()
	if self.fileExtension == "" then
		return self.name
	end

	return self.name .. "." .. self.fileExtension
end

return Executable