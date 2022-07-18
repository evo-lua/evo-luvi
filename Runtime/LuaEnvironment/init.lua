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

local uv = require('uv')
local luvi = require('luvi')
local miniz = require('miniz')

local CLI = require("CLI")

local luviBundle = require('luvibundle')
local commonBundle = luviBundle.commonBundle
local makeBundle = luviBundle.makeBundle
local buildBundle = luviBundle.buildBundle

local EXIT_SUCCESS = 0
local LUVI_EXECUTABLE_NAME = "evo-luvi"

local Luvi = {}

function Luvi:LuaMain(commandLineArgumentsPassedFromC)

	local executablePath = uv.exepath()
	if self:IsZipApp(executablePath) then
		return self:RunLuviApp(executablePath, commandLineArgumentsPassedFromC)
	end

	local commandInfo = CLI:ParseCommandLineArguments(commandLineArgumentsPassedFromC)
	self:DisplayVersionStrings(commandInfo)
	self:DisplayHelpText(commandInfo)

	-- Don't run app when printing version or help
	if commandInfo.options.version or commandInfo.options.help then
		return EXIT_SUCCESS
	end

	-- Build the app if output is given
	if commandInfo.options.output then
		return buildBundle(commandInfo.options.output, makeBundle({ commandInfo.appPath }))
	end

	-- Run the luvi app with the extra args
	return commonBundle({ commandInfo.appPath }, commandInfo.options.main, commandInfo.appArgs)
end

function Luvi:IsZipApp(filePath)
	local zip = miniz.new_reader(filePath)
	return zip ~= nil
end

function Luvi:RunLuviApp(appPath, commandLineArguments)
	return commonBundle({appPath}, nil, commandLineArguments)
end

function Luvi:DisplayVersionStrings(commandInfo)
	if not commandInfo.options.version then return end

	print(string.format("%s %s", LUVI_EXECUTABLE_NAME, luvi.version))
	print(self:GenerateOptionsString())
end

function Luvi:GenerateOptionsString()
	local optionsStringTokens = {}

	for key, value in pairs(luvi.options) do
		if type(value) == 'boolean' then
			table.insert(optionsStringTokens, key)
		else
			table.insert(optionsStringTokens, string.format("%s: %s", key, value))
		end
	end

	return table.concat(optionsStringTokens, "\n")
end

function Luvi:DisplayHelpText(commandInfo)
	if not commandInfo.options.help then return end

	local usage = [[
		Usage: $(LUVI) bundle+ [options] [-- extra args]

		  bundle            Path to directory or zip file containing bundle source.
							`bundle` can be specified multiple times to layer bundles
							on top of each other.
		  --version         Show luvi version and compiled in options.
		  --output target   Build a luvi app by zipping the bundle and inserting luvi.
		  --main path       Specify a custom main bundle path (normally main.lua)
		  --help            Show this help file.
		  --                All args after this go to the luvi app itself.

		Examples:

		  # Run an app from disk, but pass in arguments
		  $(LUVI) path/to/app -- app args

		  # Run from a app zip
		  $(LUVI) path/to/app.zip

		  # Run an app that layers on top of luvit
		  $(LUVI) path/to/app path/to/luvit

		  # Bundle an app with luvi to create standalone
		  $(LUVI) path/to/app -o target
		  ./target some args

		  # Run unit tests for a luvi app using custom main
		  $(LUVI) path/to/app -m tests/run.lua
	]]
	print((string.gsub(usage, "%$%(LUVI%)", LUVI_EXECUTABLE_NAME)))
end

return function(args)
	return Luvi:LuaMain(args)
end
