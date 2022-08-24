local StaticLibrary = import("../../BuildScripts/Ninja/StaticLibrary.lua")
local GnuCompilerCollectionRule = import("../../BuildScripts/Ninja/BuildRules/GnuCompilerCollectionRule.lua")
local BytecodeGenerationRule = import("../../BuildScripts/Ninja/BuildRules/BytecodeGenerationRule.lua")
local GnuArchiveCreationRule = import("../../BuildScripts/Ninja/BuildRules/GnuArchiveCreationRule.lua")
local ExternalMakefileProjectRule = import("../../BuildScripts/Ninja/BuildRules/ExternalMakefileProjectRule.lua")
local ExternalCMakeProjectRule = import("../../BuildScripts/Ninja/BuildRules/ExternalCMakeProjectRule.lua")

local ffi = require("ffi")
local isWindows = (ffi.os == "Windows")

local path_join = path.join

describe("StaticLibrary", function()
	describe("GetName", function()
		it("should return a library name according to the OS conventions", function()

			local target = StaticLibrary("hello")
			if isWindows then
				assertEquals(target:GetName(), "hello.lib")
			else
				assertEquals(target:GetName(), "libhello.a")
			end
		end)
	end)

	describe("GetBuildRules", function()
		it("should return a set of build rules for the default GCC/LuaJIT toolchain", function()
			local target = StaticLibrary("mylib")

			local expectedBuildRules = {
				compile = GnuCompilerCollectionRule(),
				bcsave = BytecodeGenerationRule(),
				archive = GnuArchiveCreationRule(),
				make = ExternalMakefileProjectRule(),
				cmake = ExternalCMakeProjectRule(),
				"compile",
				"bcsave",
				"archive",
				"make",
				"cmake",
			}
			assertEquals(target:GetBuildRules(), expectedBuildRules)
		end)
	end)

	describe("CreateBuildFile", function()
		it("should add declarations for all default variables to the generated build file", function()
			local target = StaticLibrary("mylib")
			local ninjaFile = target:CreateBuildFile()

			assertEquals(type(ninjaFile.variables.cwd), "string")
			assertEquals(type(ninjaFile.variables.builddir), "string")
			assertEquals(type(ninjaFile.variables.includes), "string")
		end)

		it("should add build edges for all sources to the generated build file", function()
			local target = StaticLibrary("mylib")
			local ninjaFile = target:CreateBuildFile()
			assertEquals(#ninjaFile.buildEdges, 0)

			target:AddFile("hello.c")
			ninjaFile = target:CreateBuildFile()
			assertEquals(#ninjaFile.buildEdges, 2) -- The library and the added file (.c to .o)

			target:AddFiles({ "test.c", "asdf.lua" })
			ninjaFile = target:CreateBuildFile()
			assertEquals(#ninjaFile.buildEdges, 4) -- One edge per newly-added file (plus the modified archive command)
		end)

		it("should add declarations for all default build rules to the generated build file", function()
			local target = StaticLibrary("mylib")
			local ninjaFile = target:CreateBuildFile()

			assertEquals(type(ninjaFile.ruleDeclarations.compile), "table")
			assertEquals(type(ninjaFile.ruleDeclarations.bcsave), "table")
			assertEquals(type(ninjaFile.ruleDeclarations.archive), "table")
			assertEquals(type(ninjaFile.ruleDeclarations.make), "table")
			assertEquals(type(ninjaFile.ruleDeclarations.cmake), "table")

		end)
	end)

	describe("CreateArchiveBuildEdge", function()
		it("should return a valid build edge when a single C source was added", function() end)
		it("should return a valid build edge when a single Lua source was added", function() end)
		it("should return a valid build edge when multiple C or Lua sources was added", function() end)

		it("should return nil when no sources were added", function()
			local target = StaticLibrary("mylib")
			local path, tokens, overrides = target:CreateArchiveBuildEdge()
			assertEquals(path, nil)
			assertEquals(tokens, nil)
			assertEquals(overrides, nil)
		end)

		it("should return nil when a single Makefile source was added", function()
			local target = StaticLibrary("mylib")
			target:AddFile("Makefile")
			local path, tokens, overrides = target:CreateArchiveBuildEdge()
			assertEquals(path, nil)
			assertEquals(tokens, nil)
			assertEquals(overrides, nil)
		end)

		it("should return nil when a single CMakeLists.txt source was added", function()
			local target = StaticLibrary("mylib")
			target:AddFile("CMakeLists.txt")
			local path, tokens, overrides = target:CreateArchiveBuildEdge()
			assertEquals(path, nil)
			assertEquals(tokens, nil)
			assertEquals(overrides, nil)
		end)
	end)

	describe("CreateCompilerBuildEdge", function()
		it("should raise an error if an unsupported file type was passed", function()
			local target = StaticLibrary("mylib")
			local function codeUnderTest()
				target:CreateCompilerBuildEdge("Some/directory/invalid.png")
			end

			local expectedErrorMessage = "Failed to create build edge for input Some/directory/invalid.png (unsupported file type: *.png)"
			assertThrows(codeUnderTest, expectedErrorMessage)
		end)


		it("should return a build edge connecting the library with the input file when a C file was passed", function()
			local target = StaticLibrary("mylib")
			local sourcePath = path_join("Some", "directory", "something.c")

			local path, tokens, overrides = target:CreateCompilerBuildEdge(sourcePath)

			assertEquals(path, path_join("$builddir", "mylib", "something.c.o"))
			assertEquals(tokens, { "compile", sourcePath })
			assertEquals(overrides, {{ name = "includes", declarationLine = "$includes"}})
		end)

		it("should return a build edge connecting the library with the input file when a Lua file was passed", function()
			local target = StaticLibrary("mylib")
			local sourcePath = path_join("Some", "directory", "something.lua")

			local path, tokens, overrides = target:CreateCompilerBuildEdge(sourcePath)

			assertEquals(path, path_join("$builddir", "mylib", "something.lua.o"))
			assertEquals(tokens, { "bcsave", sourcePath})
			assertEquals(overrides, {})
		end)

		it("should return nil when a Makefile was passed", function()
			local target = StaticLibrary("mylib")
			local sourcePath = path_join("Some", "directory", "Makefile")

			local path, tokens, overrides = target:CreateCompilerBuildEdge(sourcePath)

			assertEquals(path, nil)
			assertEquals(tokens, nil)
			assertEquals(overrides, nil)
		end)

		it("should return nil when a CMakeLists.txt file was passed", function()
			local target = StaticLibrary("mylib")
			local sourcePath = path_join("Some", "directory", "CMakeLists.txt")

			local path, tokens, overrides = target:CreateCompilerBuildEdge(sourcePath)

			assertEquals(path, nil)
			assertEquals(tokens, nil)
			assertEquals(overrides, nil)
		end)
	end)
end)