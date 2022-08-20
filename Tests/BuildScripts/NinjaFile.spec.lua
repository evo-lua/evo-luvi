local NinjaFile = import("../../BuildScripts/Ninja/NinjaFile.lua")

describe("NinjaFile", function()
	describe("Construct", function()
		local ninjaFile = NinjaFile()

		it("should initialize the file with a minimum required version", function()
			assertEquals(ninjaFile.requiredVersion, ninjaFile.DEFAULT_REQUIRED_VERSION)
		end)

		it("should initialize the file with the default build directory path", function()
			assertEquals(ninjaFile.buildDirectory, ninjaFile.DEFAULT_BUILD_DIRECTORY_NAME)
		end)

	end)

	describe("Save", function()
		local ninjaFile = NinjaFile()
		-- TODO
	end)

	describe("AddVariable", function() end)

	describe("AddRule", function() end)

	describe("ToString", function()

		it("should include only the auto-generation header notice if no declarations have been added", function()
			local ninjaFile = NinjaFile()

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT .. "\n"
			 .. "ninja_required_version = " .. ninjaFile.requiredVersion
			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for the variable declarations if any have been added", function()
			local ninjaFile = NinjaFile()

			ninjaFile:AddVariable("root_dir", "file/path")

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT .. "\n"
			.. "ninja_required_version = " .. ninjaFile.requiredVersion  .. "\n"
			.. "root_dir = " .. "file/path"

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for the rule declarations if any have been added", function()
			local ninjaFile = NinjaFile()

			local ruleInfo = {
				{ name = "command", "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "-o", "$out" },
				{ name = "description", "CC", "$out" },
				{ name = "depfile", "$out.d" },
				{ name = "deps", "gcc" },
			}

			ninjaFile:AddRule("compile", ruleInfo)

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT .. "\n"
			.. "ninja_required_version = " .. ninjaFile.requiredVersion  .. "\n"
			.. "rule compile" .. "\n" ..
			"  " .. "command = gcc -MMD -MT $out -MF $out.d -c $in -o $out".. "\n" ..
			"  " .. "description = CC $out".. "\n" ..
			"  " .. "depfile = $out.d".. "\n" ..
			"  " .. "deps = gcc"

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for the build edges if any have been added", function()
			local ninjaFile = NinjaFile()

			local buildEdge = {
				target = "target.o",
				statementTokens = {	"compile", "target.c" },
				variableOverrides = {
					{
						name = "includes",
						declarationLine = "-Iinclude_dir", -- TBD tokens?
					}
				}
			}

			ninjaFile.buildEdges = { -- NinjaFile:AddBuildEdge("target.o", "target.c", overrides)
				buildEdge,
			}

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT .. "\n"
			.. "ninja_required_version = " .. ninjaFile.requiredVersion  .. "\n"
			.. "build target.o: compile target.c" .. "\n" ..
			"  " .. "includes = -Iinclude_dir"

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)
	end)
end)
