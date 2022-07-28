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

local Luvi = {
	executablePath = uv.exepath(),
	commandLineArguments = {},
}

function Luvi:LoadExtensionModules()
	local primitives = require("primitives")
	local extensionLoaders = require("extensions")
	local apiNamespaces = require("namespaces")

	-- Preload primitives (they shouldn't be available globally, but extensions may depend on them)
	for name, primitiveLoader in pairs(primitives) do
		package.preload[name] = primitiveLoader()
	end

	-- Insert extension modules in the global namespace so they're available to user scripts and high-level libraries
	for name, extensionLoader in pairs(extensionLoaders) do
		_G[name] = extensionLoader()
	end

	-- Load after extensions since they will be used deliberately
	for name, namespaceLoader in pairs(apiNamespaces) do
		_G[name] = namespaceLoader()
	end
end

-- They need to be loaded before any Lua modules are required or they won't be available in time
Luvi:LoadExtensionModules()

local CLI = require("CLI")

function Luvi:LuaMain(commandLineArgumentsPassedFromC)
	self.commandLineArguments = commandLineArgumentsPassedFromC

	-- When the executable contains a luvi-based app, it should be run instead of the default CLI
	if self:IsZipApp() then
		return self:StartBundledApp()
	end

	return self:StartCommandLineParser()
end

function Luvi:StartBundledApp()
	local commandInfo = {
		appPath = self.executablePath,
		appArgs = self.commandLineArguments,
		options = {},
	}
	return CLI:ExecuteCommand(commandInfo)
end

function Luvi:StartCommandLineParser()
	local commandInfo = CLI:ParseCommandLineArguments(self.commandLineArguments)
	return CLI:ExecuteCommand(commandInfo)
end

function Luvi:IsZipApp()
	local zip = miniz.new_reader(self.executablePath)
	return zip ~= nil
end

local function StartMainThread(args)
	local mainThread = coroutine.wrap(function()
		return Luvi:LuaMain(args)
	end)
	local exitCode = mainThread()
	uv.run()
	return exitCode
end

return StartMainThread
