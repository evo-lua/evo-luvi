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
		-- TODO Remove
		-- ninjaFile:Save("test.ninja")
	end)

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

			ninjaFile.variables = { -- NinjaFile:AddVariable("root_dir", "deps/llhttp-ffi/llhttp")
				{
					name = "root_dir",
					declarationLine = "deps/llhttp-ffi/llhttp",
				}
			}

			local stringifiedNinjaFile = ninjaFile:ToString()
			local expectedFileContents = ninjaFile.AUTOGENERATION_HEADER_TEXT .. "\n"
			.. "ninja_required_version = " .. ninjaFile.requiredVersion  .. "\n"
			.. "root_dir = " .. "deps/llhttp-ffi/llhttp"

			-- TODO Remove
			ninjaFile:Save("test.ninja")

			assertEquals(stringifiedNinjaFile, expectedFileContents)
		end)

	end)
end)
