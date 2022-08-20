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

	end)
end)