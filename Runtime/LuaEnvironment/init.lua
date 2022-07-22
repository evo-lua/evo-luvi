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

local luviBundle = require("luvibundle")
local commonBundle = luviBundle.commonBundle

local Luvi = {}

function Luvi:LuaMain(commandLineArgumentsPassedFromC)
	local executablePath = uv.exepath()
	if self:IsZipApp(executablePath) then
		return self:RunLuviApp(executablePath, commandLineArgumentsPassedFromC)
	end

	local commandInfo = CLI:ParseCommandLineArguments(commandLineArgumentsPassedFromC)

	return CLI:ExecuteCommand(commandInfo)
end

function Luvi:IsZipApp(filePath)
	local zip = miniz.new_reader(filePath)
	return zip ~= nil
end

function Luvi:RunLuviApp(appPath, commandLineArguments)
	return commonBundle(appPath, nil, commandLineArguments)
end

return function(args)
	return Luvi:LuaMain(args)
end
