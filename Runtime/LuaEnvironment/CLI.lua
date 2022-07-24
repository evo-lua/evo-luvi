local CLI = {
	print = print, -- Only needed for injecting faux consoles (during testing). Not pretty, but alas...
	COMBINED_BUNDLES_ERROR = "Merging multiple bundles is no longer supported; "
		.. "please restructure your application to use a single entry point instead",
}

function CLI:ParseCommandLineArguments(argumentsVector)
	if type(argumentsVector) ~= "table" then
		error("Usage: ParseCommandLineArguments(argumentsVector : table)", 0)
	end
	local bundles = {}
	local options = {}
	local appArgs = {}

	local key
	for i = 1, #argumentsVector do
		local arg = argumentsVector[i]
		if arg == "--" then
			if #bundles == 0 then
				i = i + 1
				bundles[1] = argumentsVector[i]
			end
			for j = i + 1, #argumentsVector do
				appArgs[#appArgs + 1] = argumentsVector[j]
			end
			break
		elseif key then
			options[key] = arg
			key = nil
		else
			local command = CLI.COMMAND_HANDLERS[arg]
			if options[command] then
				error("Duplicate flags: " .. command, 0)
			end
			if command == "output" or command == "main" then
				key = command
			elseif command then
				options[command] = true
			else
				if arg:sub(1, 1) == "-" then
					error("Unknown flag: " .. arg, 0)
				end
				bundles[#bundles + 1] = arg
			end
		end
	end

	if #bundles > 1 then
		error(self.COMBINED_BUNDLES_ERROR, 0)
	end
	if key then
		error("Missing value for option: " .. key, 0)
	end

	-- Show help and version by default
	if #bundles == 0 and not options.version and not options.help then
		options.version = true
		options.help = true
	end

	return { appPath = bundles[1] or "", options = options, appArgs = appArgs }
end

local LuviAppBundle = require("LuviAppBundle")

local EXIT_SUCCESS = 0

function CLI:ExecuteCommand(commandInfo)
	if type(commandInfo) ~= "table" then
		error("No command to execute", 0)
	end

	local print = self.print

	if commandInfo.options.version then
		print(self:GetVersionText())
	end

	if commandInfo.options.help then
		print(self:GetHelpText())
	end

	-- Don't run app when printing version or help
	if commandInfo.options.version or commandInfo.options.help then
		return EXIT_SUCCESS
	end

	local bundle = LuviAppBundle(commandInfo.appPath, commandInfo.options.main)
	if commandInfo.options.output then
		return bundle:CreateZipApp(commandInfo.options.output)
	end

	return bundle:RunContainedApp(commandInfo.appArgs)
end

function CLI:SetConsole(console)
	self.print = console and console.print or print
end

local luvi = require("luvi")
local jit = require("jit")

function CLI:GetVersionText()
	-- Generate options string
	local optionsStringTokens = {}

	for key, value in pairs(luvi.options) do
		if type(value) == "boolean" then
			table.insert(optionsStringTokens, key)
		else
			table.insert(optionsStringTokens, string.format("\t%s\t%s", key, value))
		end
	end
	local optionsString = table.concat(optionsStringTokens, "\n")

	return string.format("This is evo-luvi %s (powered by %s)", luvi.version, jit.version)
		.. "\n\nEmbedded libraries:\n\n"
		.. optionsString
		.. "\n"
end

function CLI:GetHelpText()
	local helpText = [[Usage: $(LUVI) entryPoint [runtimeOptions] [-- applicationOptions]

    entryPoint		Path to the entry point of your application (lua, zip, or directory)

    runtimeOptions	One or several of the following command line flags:

        -h, --help		Display usage information (this text)
        -v, --version		Show versioning information in a human-readable format
        -o, --output path	Create a self-contained executable that runs your application
        -m, --main path		Specify a nonstandard entry point (defaults to main.lua)

    --			Indicate the end of runTimeOptions (everything after this will be ignored)

    applicationOptions	Command line flags that are forwarded to your application

For documentation and examples, visit https://evo-lua.github.io/]]
	helpText = string.gsub(helpText, "%$%(LUVI%)", self.EXECUTABLE_NAME) -- Discard number of matches
	return helpText
end

CLI.COMMAND_HANDLERS = {
	["-o"] = "output",
	["--output"] = "output",
	["-m"] = "main",
	["--main"] = "main",
	["-v"] = "version",
	["--version"] = "version",
	["-h"] = "help",
	["--help"] = "help",
}

CLI.EXECUTABLE_NAME = "evo-luvi"

return CLI
