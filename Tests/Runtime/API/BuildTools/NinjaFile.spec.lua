local NinjaFile = import("../../../../Runtime/API/BuildTools/NinjaFile.lua")

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
		local testFilePath = path.join("Tests", "Fixtures", "temp.ninja")
		before(function()
			assertFalse(C_FileSystem.Exists(testFilePath))
		end)

		after(function()
			C_FileSystem.Delete(testFilePath)
			assertFalse(C_FileSystem.Exists(testFilePath))
		end)

		it("should write the serialized file contents to the given file location", function()
			local ninjaFile = NinjaFile()
			local expectedFileContents = ninjaFile:ToString()

			ninjaFile:Save(testFilePath)

			local actualFileContents = C_FileSystem.ReadFile(testFilePath)
			assertEquals(actualFileContents, expectedFileContents)
		end)
	end)

	describe("ToString", function()
		it("should include only the auto-generation header notice if no declarations have been added", function()
			local ninjaFile = NinjaFile()

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT
				.. "\n"
				.. "ninja_required_version = "
				.. ninjaFile.requiredVersion
				.. "\n"
			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for the variable declarations if any have been added", function()
			local ninjaFile = NinjaFile()

			ninjaFile:AddVariable("root_dir", "file/path")

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT
				.. "\n"
				.. "ninja_required_version = "
				.. ninjaFile.requiredVersion
				.. "\n"
				.. "\n# Variable declarations"
				.. "\n"
				.. "root_dir = "
				.. "file/path"
				.. "\n"

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for the rule declarations if any have been added", function()
			local ninjaFile = NinjaFile()

			ninjaFile:AddRule(
				"compile",
				"$C_COMPILER -c $in -o $out -MT $out -MMD -MF $out.d $COMPILER_FLAGS $includes $defines",
				{
					description = "Compiling $in ...",
					deps = "$C_COMPILER",
					depfile = "$out.d",
				}
			)

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT
				.. "\n"
				.. "ninja_required_version = "
				.. ninjaFile.requiredVersion
				.. "\n"
				.. [[

# Build rules
rule compile
  command = $C_COMPILER -c $in -o $out -MT $out -MMD -MF $out.d $COMPILER_FLAGS $includes $defines
  description = Compiling $in ...
  deps = $C_COMPILER
  depfile = $out.d
]]

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for the build edges if any have been added", function()
			local ninjaFile = NinjaFile()

			ninjaFile:AddBuildEdge("target.o", "compile target.c", {
				includes = "-Iinclude_dir",
			})

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT
				.. "\n"
				.. "ninja_required_version = "
				.. ninjaFile.requiredVersion
				.. "\n"
				.. "\n# Build edges"
				.. "\n"
				.. "build target.o: compile target.c"
				.. "\n"
				.. "  "
				.. "includes = -Iinclude_dir"
				.. "\n"

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

		it("should include a section for included files if any have been added", function()
			local ninjaFile = NinjaFile()

			ninjaFile:AddInclude("another_project")

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT
				.. "\n"
				.. "ninja_required_version = "
				.. ninjaFile.requiredVersion
				.. "\n"
				.. "\n# Includes"
				.. "\n"
				.. "subninja another_project.ninja"
				.. "\n"

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)
	end)
end)
