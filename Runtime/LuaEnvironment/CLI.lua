local CLI = {}

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

    if key then error("Missing value for option: " .. key, 0) end

    -- Show help and version by default
    if #bundles == 0 and not options.version and not options.help then
        options.version = true
        options.help = true
    end

    return {bundles = bundles, options = options, appArgs = appArgs}

end

CLI.COMMAND_HANDLERS = {
    ["-o"] = "output",
    ["--output"] = "output",
    ["-m"] = "main",
    ["--main"] = "main",
    ["-v"] = "version",
    ["--version"] = "version",
    ["-h"] = "help",
    ["--help"] = "help"
}

return CLI
