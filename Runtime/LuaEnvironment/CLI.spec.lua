require("busted.runner")()

local CLI = import("CLI.lua")

describe("ParseCommandLineArguments", function()
	it("should raise an error if a non-table value was passed", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments)
		assert.is_false(success)
		assert.equals("Usage: ParseCommandLineArguments(argumentsVector : table)", errorMessage)
	end)

	it("should display the version string and help text by default", function()
		local commandInfo = CLI:ParseCommandLineArguments({})
		local expectedCommandInfo = {
			options = {
				help = true,
				version = true,
			},
			appPath = "",
			appArgs = {},
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should raise an error if the --output flag is set but no file path was provided", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-o" })
		assert.is_false(success)
		assert.equals("Missing value for option: output", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--output" })
		assert.is_false(success)
		assert.equals("Missing value for option: output", errorMessage)
	end)

	it("should raise an error if the --main flag is set but no file path was provided", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-m" })
		assert.is_false(success)
		assert.equals("Missing value for option: main", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--main" })
		assert.is_false(success)
		assert.equals("Missing value for option: main", errorMessage)
	end)

	it("should raise an error if an invalid flag was passed", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-" })
		assert.is_false(success)
		assert.equals("Unknown flag: -", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-invalid" })
		assert.is_false(success)
		assert.equals("Unknown flag: -invalid", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--invalid" })
		assert.is_false(success)
		assert.equals("Unknown flag: --invalid", errorMessage)
	end)

	it("should display the version string if only the --version flag is set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "--version" })
		local expectedCommandInfo = {
			options = {
				version = true,
			},
			appPath = "",
			appArgs = {},
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should display the version string if only the -v flag is set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "-v" })
		local expectedCommandInfo = {
			options = {
				version = true,
			},
			appPath = "",
			appArgs = {},
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should display the help text if only the --help flag is set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "--help" })
		local expectedCommandInfo = {
			options = {
				help = true,
			},
			appPath = "",
			appArgs = {},
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should display the help text if only the -h flag is set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "-h" })
		local expectedCommandInfo = {
			options = {
				help = true,
			},
			appPath = "",
			appArgs = {},
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should raise an error if a valid flag is set more than once", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--help", "--help" })
		assert.is_false(success)
		assert.equals("Duplicate flags: help", errorMessage)
	end)

	-- TBD: Why?
	it("should use the first argument after the -- separator as the bundle path if no other paths were set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "--", "wtf.lua", "something", "42" })
		local expectedCommandInfo = {
			options = {},
			appPath = "wtf.lua",
			appArgs = { "something", "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should use the argument before the -- separator as the bundle path if only one was set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "--", "something", "42" })
		local expectedCommandInfo = {
			options = {},
			appPath = "file1.lua",
			appArgs = { "something", "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should use all arguments before the -- separator as the bundle paths if more than one was set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "--", "something", "42" })
		local expectedCommandInfo = {
			options = {},
			appPath = "file1.lua",
			appArgs = { "something", "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should use the argument after the --output flag as the executable path", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "--output", "something.exe", "--", "42" })
		local expectedCommandInfo = {
			options = {
				output = "something.exe",
			},
			appPath = "file1.lua",
			appArgs = { "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should use the argument after the -o flag as the executable path", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "-o", "something.exe", "--", "42" })
		local expectedCommandInfo = {
			options = {
				output = "something.exe",
			},
			appPath = "file1.lua",
			appArgs = { "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should use the argument after the --main flag as the executable path", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "--main", "something.lua", "--", "42" })
		local expectedCommandInfo = {
			options = {
				main = "something.lua",
			},
			appPath = "file1.lua",
			appArgs = { "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should use the argument after the -m flag as the entry point", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "-m", "something.lua", "--", "42" })
		local expectedCommandInfo = {
			options = {
				main = "something.lua",
			},
			appPath = "file1.lua",
			appArgs = { "42" },
		}
		assert.same(expectedCommandInfo, commandInfo)
	end)

	it("should raise an error if multiple bundle paths were passed", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "script.lua", "anotherFile.zip" })
		assert.is_false(success)
		assert.equals(CLI.COMBINED_BUNDLES_ERROR, errorMessage)
	end)
end)
