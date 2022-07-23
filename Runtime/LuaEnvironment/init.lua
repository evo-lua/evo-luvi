--[[

Copyright 2014 The Luvit Authors. All Rights Reserved.

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS-IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

--]]

local uv = require("uv")
local miniz = require("miniz")

local CLI = require("CLI")

local Luvi = {
	executablePath = uv.exepath()
}

function Luvi:LuaMain(commandLineArgumentsPassedFromC)
	self:LoadExtensionModules()

	local commandInfo
	if self:IsZipApp() then
		-- Since the executable is a luvi-based app, it should be run instead of the default (embedded) luvi engine
		commandInfo = {
			appPath = self.executablePath,
			appArgs = commandLineArgumentsPassedFromC,
			options = {},
		}
	else
		commandInfo = CLI:ParseCommandLineArguments(commandLineArgumentsPassedFromC)
	end

	return CLI:ExecuteCommand(commandInfo)
end

function Luvi:LoadExtensionModules()
	local primitives = require("primitives")
	local extensionLoaders = require("extensions")

	-- Preload primitives (they shouldn't be available globally, but extensions may depend on them)
	for name, primitiveLoader in pairs(primitives) do
		package.preload[name] = primitiveLoader()
	end

	-- Insert extension modules in the global namespace so they're available to user scripts and high-level libraries
	for name, extensionLoader in pairs(extensionLoaders) do
		_G[name] = extensionLoader()
	end
end

function Luvi:IsZipApp()
	local zip = miniz.new_reader(self.executablePath)
	return zip ~= nil
end

return function(args)
	return Luvi:LuaMain(args)
end
