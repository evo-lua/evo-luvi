local uv = require("uv")

local CLI = require("CLI")

describe("ParseCommandLineArguments", function()
	it("should raise an error if a non-table value was passed", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments)
		assertFalse(success)
		assertEquals("Usage: ParseCommandLineArguments(argumentsVector : table)", errorMessage)
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
		assertEquals(expectedCommandInfo, commandInfo)
	end)

	it("should raise an error if the --output flag is set but no file path was provided", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-o" })
		assertFalse(success)
		assertEquals("Missing value for option: output", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--output" })
		assertFalse(success)
		assertEquals("Missing value for option: output", errorMessage)
	end)

	it("should raise an error if the --main flag is set but no file path was provided", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-m" })
		assertFalse(success)
		assertEquals("Missing value for option: main", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--main" })
		assertFalse(success)
		assertEquals("Missing value for option: main", errorMessage)
	end)

	it("should raise an error if an invalid flag was passed", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-" })
		assertFalse(success)
		assertEquals("Unknown flag: -", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "-invalid" })
		assertFalse(success)
		assertEquals("Unknown flag: -invalid", errorMessage)

		success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--invalid" })
		assertFalse(success)
		assertEquals("Unknown flag: --invalid", errorMessage)
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
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
	end)

	it("should raise an error if a valid flag is set more than once", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "--help", "--help" })
		assertFalse(success)
		assertEquals("Duplicate flags: help", errorMessage)
	end)

	-- TBD: Why?
	it("should use the first argument after the -- separator as the bundle path if no other paths were set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "--", "wtf.lua", "something", "42" })
		local expectedCommandInfo = {
			options = {},
			appPath = "wtf.lua",
			appArgs = { "something", "42" },
		}
		assertEquals(expectedCommandInfo, commandInfo)
	end)

	it("should use the argument before the -- separator as the bundle path if only one was set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "--", "something", "42" })
		local expectedCommandInfo = {
			options = {},
			appPath = "file1.lua",
			appArgs = { "something", "42" },
		}
		assertEquals(expectedCommandInfo, commandInfo)
	end)

	it("should use all arguments before the -- separator as the bundle paths if more than one was set", function()
		local commandInfo = CLI:ParseCommandLineArguments({ "file1.lua", "--", "something", "42" })
		local expectedCommandInfo = {
			options = {},
			appPath = "file1.lua",
			appArgs = { "something", "42" },
		}
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
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
		assertEquals(expectedCommandInfo, commandInfo)
	end)

	it("should raise an error if multiple bundle paths were passed", function()
		local success, errorMessage = pcall(CLI.ParseCommandLineArguments, CLI, { "script.lua", "anotherFile.zip" })
		assertFalse(success)
		assertEquals(CLI.COMBINED_BUNDLES_ERROR, errorMessage)
	end)
end)

describe("ExecuteCommand", function()
	local ZIPAPP_EXAMPLE_FOLDER = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldZipApp")
	local ZIPAPP_EXAMPLE_OUTPUT = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldZipApp.zip")
	local REBASED_ZIPAPP_EXAMPLE_FOLDER = path.join(uv.cwd(), "Tests", "Fixtures", "RebasedZipApp")
	local REBASED_ZIPAPP_EXAMPLE_OUTPUT = path.join(uv.cwd(), "Tests", "Fixtures", "RebasedZipApp.zip")
	before(function()
		local function createRegularZipApp()
			-- This is a roundabout way of calling the CLI, but it should work regardless of where the binary is located (unlike os.exec)
			local commandInfo = {
				appArgs = {},
				appPath = ZIPAPP_EXAMPLE_FOLDER,
				options = {
					output = ZIPAPP_EXAMPLE_OUTPUT,
				},
			}
			-- The zip app is platform-specific, so it needs to be created from scratch. Also, we don't want to track zip files via git...
			CLI:ExecuteCommand(commandInfo)

			assert(uv.fs_stat(ZIPAPP_EXAMPLE_OUTPUT), "Failed to create temporary file: " .. ZIPAPP_EXAMPLE_OUTPUT)
		end

		local function createRebasedZipApp()
			local commandInfo = {
				appArgs = {},
				appPath = REBASED_ZIPAPP_EXAMPLE_FOLDER,
				options = {
					output = REBASED_ZIPAPP_EXAMPLE_OUTPUT,
				},
			}
			CLI:ExecuteCommand(commandInfo)

			assert(
				uv.fs_stat(REBASED_ZIPAPP_EXAMPLE_OUTPUT),
				"Failed to create temporary file: " .. REBASED_ZIPAPP_EXAMPLE_OUTPUT
			)
		end

		createRegularZipApp()
		createRebasedZipApp()
	end)

	after(function()
		assert(uv.fs_unlink(ZIPAPP_EXAMPLE_OUTPUT), "Failed to remove temporary file " .. ZIPAPP_EXAMPLE_OUTPUT)
		assert(
			uv.fs_unlink(REBASED_ZIPAPP_EXAMPLE_OUTPUT),
			"Failed to remove temporary file " .. REBASED_ZIPAPP_EXAMPLE_OUTPUT
		)
	end)

	it("should raise an error if no command was passed", function()
		assertThrows(function()
			CLI:ExecuteCommand(nil)
		end, "No command to execute")
	end)

	it("should display the version string if the -v or --version flags were passed", function()
		local commandInfo = {
			appPath = "",
			appArgs = {},
			options = {
				version = true,
			},
		}

		local fauxConsole = C_Testing.CreateFauxConsole()
		CLI:SetConsole(fauxConsole)
		CLI:ExecuteCommand(commandInfo)
		assertEquals(CLI:GetVersionText() .. "\n", fauxConsole:read())
	end)

	it("should display the help text if the -h or --help flags were passed", function()
		local commandInfo = {
			appPath = "",
			appArgs = {},
			options = {
				help = true,
			},
		}

		local fauxConsole = C_Testing.CreateFauxConsole()
		CLI:SetConsole(fauxConsole)
		CLI:ExecuteCommand(commandInfo)
		assertEquals(CLI:GetHelpText() .. "\n", fauxConsole:read())
	end)

	it("should display the help text and version if both the -h and -v flags were passed", function()
		local commandInfo = {
			appPath = "",
			appArgs = {},
			options = {
				help = true,
				version = true,
			},
		}

		local fauxConsole = C_Testing.CreateFauxConsole()
		CLI:SetConsole(fauxConsole)
		CLI:ExecuteCommand(commandInfo)

		local expectedConsoleOutput = CLI:GetVersionText() .. "\n" .. CLI:GetHelpText() .. "\n"
		assertEquals(expectedConsoleOutput, fauxConsole:read())
	end)

	it("should load the default entry point if a folder was passed without the optional -m flag", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp"),
			appArgs = { "appArg1", "appArg2" },
			options = {},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("HelloWorldApp/main.lua (disk)#appArg1#appArg2", moduleReturns)
	end)

	it("should load the given entry point if a folder was passed with a valid -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp"),
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "entry.lua",
			},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("HelloWorldApp/entry.lua (disk)#appArg1#appArg2", moduleReturns)
	end)

	it("should raise an error if a folder was passed with in invalid -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp"),
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "invalid.lua",
			},
		}
		local function codeUnderTest()
			CLI:ExecuteCommand(commandInfo)
		end
		local expectedErrorMessage =
			string.format("Entry point %s does not exist in app bundle %s", "invalid.lua", commandInfo.appPath)
		assertThrows(codeUnderTest, expectedErrorMessage)
	end)

	it("should load the given file if a lua file was passed without an optional -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp", "entry.lua"),
			appArgs = { "appArg1", "appArg2" },
			options = {},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("HelloWorldApp/entry.lua (disk)#appArg1#appArg2", moduleReturns)
	end)

	it("should load the file itself and not the main path if a lua file was passed with a valid -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp", "entry.lua"),
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "main.lua",
			},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("HelloWorldApp/entry.lua (disk)#appArg1#appArg2", moduleReturns)
	end)

	it("should raise an error if an invalid lua file path was passed without an optional -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp", "invalid.lua"),
			appArgs = { "appArg1", "appArg2" },
			options = {},
		}
		local function codeUnderTest()
			CLI:ExecuteCommand(commandInfo)
		end
		local expectedErrorMessage = string.format("Failed to load %s (No such file exists)", commandInfo.appPath)
		assertThrows(codeUnderTest, expectedErrorMessage)
	end)

	it("should raise an error ignoring the main path if a lua file was passed with in invalid -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldApp", "doesnotexist.lua"),
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "invalid.lua",
			},
		}
		local function codeUnderTest()
			CLI:ExecuteCommand(commandInfo)
		end
		local expectedErrorMessage = string.format("Failed to load %s (No such file exists)", commandInfo.appPath)
		assertThrows(codeUnderTest, expectedErrorMessage)
	end)

	it("should raise an error if a zip file was passed with in invalid -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldZipApp.zip"),
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "invalid.lua",
			},
		}
		local function codeUnderTest()
			CLI:ExecuteCommand(commandInfo)
		end
		local expectedErrorMessage =
			string.format("Entry point %s does not exist in app bundle %s", "invalid.lua", commandInfo.appPath)
		assertThrows(codeUnderTest, expectedErrorMessage)
	end)

	it("should load the default entry point if a zip file was passed without the optional -m flag", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldZipApp.zip"),
			appArgs = { "appArg1", "appArg2" },
			options = {},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("HelloWorldZipApp/main.lua (vfs)#appArg1#appArg2", moduleReturns)
	end)

	it("should load the given entry point if a zip file was passed with a valid -m path", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "HelloWorldZipApp.zip"),
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "entry.lua",
			},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("HelloWorldZipApp/entry.lua (vfs)#appArg1#appArg2", moduleReturns)
	end)

	it(
		"should load the default entry point if a zip file that needs rebasing was passed without the optional -m flag",
		function()
			local commandInfo = {
				appPath = REBASED_ZIPAPP_EXAMPLE_OUTPUT,
				appArgs = { "appArg1", "appArg2" },
				options = {},
			}
			local moduleReturns = CLI:ExecuteCommand(commandInfo)
			assertEquals("RebasedZipApp/app/main.lua (vfs)#appArg1#appArg2", moduleReturns)
		end
	)

	it("should load the given entry point if a zip file that needs rebasing was passed with a valid -m path", function()
		local commandInfo = {
			appPath = REBASED_ZIPAPP_EXAMPLE_OUTPUT,
			appArgs = { "appArg1", "appArg2" },
			options = {
				main = "entry.lua",
			},
		}
		local moduleReturns = CLI:ExecuteCommand(commandInfo)
		assertEquals("RebasedZipApp/app/entry.lua (vfs)#appArg1#appArg2", moduleReturns)
	end)

	it("should raise an error if an incompatible file type was passed", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "empty.txt"),
			appArgs = {},
			options = {},
		}

		assertThrows(function()
			CLI:ExecuteCommand(commandInfo)
		end, string.format("Failed to load %s (Unsupported file type)", commandInfo.appPath))
	end)

	it("should raise an error if an invalid file path was passed", function()
		local commandInfo = {
			appPath = path.join(uv.cwd(), "Tests", "Fixtures", "does-not-exist.txt"),
			appArgs = {},
			options = {},
		}

		-- Better be safe than sorry...
		assert(not uv.fs_stat(commandInfo.appPath), commandInfo.appPath .. " should not exist")

		assertThrows(function()
			CLI:ExecuteCommand(commandInfo)
		end, string.format("Failed to load %s (No such file exists)", commandInfo.appPath))
	end)
end)
