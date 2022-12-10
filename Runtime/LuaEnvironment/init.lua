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
local ffi = require("ffi")
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

	self:InitializeStaticLibraryExports()

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

function Luvi:InitializeStaticLibraryExports()
	local staticLibraryExports = _G.STATIC_FFI_EXPORTS
	if not staticLibraryExports then
		-- No static libraries present or static exports from C are unavailable? Not much to be done here...
		return
	end

	-- Libraries exposed via static FFI wrappers need to be initialized differently (approach suggested by the LuaJIT author)
	-- To avoid depedency hell, the runtime exports static "intermediary" objects to forward API calls to statically linked libraries
	-- The exact same API is used, but calls are optimized via the FFI without a DLL/SO having to be present on disk
	-- We substitute this object for the exports table that is normally added via load(), as it only works for shared libraries
	for libraryName, staticWrapperObject in pairs(staticLibraryExports) do
		local ffiBindings = require(libraryName)
		ffiBindings.initialize()
		local expectedStructName = "struct static_" .. libraryName .. "_exports_table*"
		local ffiExportsTable = ffi.cast(expectedStructName, staticWrapperObject)
		ffiBindings.bindings = ffiExportsTable
	end

	_G.STATIC_FFI_EXPORTS = nil -- They're no longer needed after the static FFI bindings have been set up
end

-- They need to be loaded before any Lua modules are required or they won't be available in time
Luvi:LoadExtensionModules()

local CLI = require("CLI")

function Luvi:LuaMain(commandLineArgumentsPassedFromC)
	self:FixLpegVersionString()
	self:FixPcreVersionString()
	self:FixMinizVersionString()

	self.commandLineArguments = commandLineArgumentsPassedFromC
	_G.arg = commandLineArgumentsPassedFromC -- Mimick the standard arg global to avoid confusing users

	-- When the executable contains a luvi-based app, it should be run instead of the default CLI
	if self:IsZipApp() then
		return self:StartBundledApp()
	end

	-- An unhandled SIGPIPE error signal will crash the server on platforms that send it, e.g. when attempting to write to a closed socket
	if uv.constants.SIGPIPE then
		local sigpipeSignal = uv.new_signal()
		sigpipeSignal:start("sigpipe")
		uv.unref(sigpipeSignal) -- This empty signal handler shouldn't prevent the event loop from exiting as it's a no-op

		-- May want to remove the handler again, so let's make finding it trivial
		local runtime = require("runtime")
		runtime.signals.SIGPIPE = sigpipeSignal
	end

	return self:StartCommandLineParser()
end

-- LPEG doesn't offer a C API, and fiddling with the Lua stack is annoying enough, so let's just do this here
function Luvi:FixLpegVersionString()
	local success, lpeg = pcall(require, "lpeg")

	if success and lpeg and lpeg.version then
		local lpegVersionString = string.match(lpeg.version, "%d+.%d+.%d+")
		require("runtime").libraries.lpeg = lpegVersionString -- This only affects the --version output
		lpeg.version = lpegVersionString -- We don't want the prefix in the API either, as it isn't very useful
	end
end

-- Lrexlib has a separate version from the embedded PCRE2, so we display both (to help debug issues)
function Luvi:FixPcreVersionString()
	local success, regex = pcall(require, "regex")

	if success and regex and regex.version() and regex._VERSION then
		local pcreVersionString = regex.version()
		local lrexlibVersion = regex._VERSION
		require("runtime").libraries.regex = pcreVersionString .. ", " .. lrexlibVersion -- This only affects the --version output
	end
end

-- There's actually a C API for this, but the miniz bindings don't have a header to include, so might as well do it here instead
function Luvi:FixMinizVersionString()
	require("runtime").libraries.miniz = miniz.version() -- This only affects the --version output
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
