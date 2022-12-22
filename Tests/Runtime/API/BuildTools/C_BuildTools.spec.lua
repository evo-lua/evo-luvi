local C_BuildTools = import("../../../../Runtime/API/BuildTools/C_BuildTools.lua")

local ffi = require("ffi")

local function assertString(value)
	local actualType = type(value)
	local expectedType = "string"

	if actualType ~= expectedType then
		error(
			transform.brightRedBackground(
				format(
					'Expected value %s to be of type "%s", but the actual type is "%s"',
					value,
					expectedType,
					actualType
				)
			),
			2
		)
	end
	assertEquals(actualType, expectedType)
end

describe("C_BuildTools", function()
	describe("GetStaticLibraryName", function()
		it("should return a standardized library name on all supported systems", function()
			local libraryBaseName = "awesome"

			-- LuaJIT docs: Can only be "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other"
			local expectedLibraryNamesPerOS = {
				["Windows"] = "awesome.lib",
				["Linux"] = "libawesome.a",
				["OSX"] = "libawesome.a",
				["BSD"] = "libawesome.a",
				["POSIX"] = "libawesome.a",
				["Other"] = "libawesome.a",
			}

			local standardizedLibraryName = C_BuildTools.GetStaticLibraryName(libraryBaseName)
			local expectedLibraryName = expectedLibraryNamesPerOS[ffi.os]
			assertEquals(standardizedLibraryName, expectedLibraryName)
		end)
	end)

	describe("GetSharedLibraryName", function()
		it("should return a standardized library name on all supported systems", function()
			local libraryBaseName = "awesome"

			-- LuaJIT docs: Can only be "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other"
			local expectedLibraryNamesPerOS = {
				["Windows"] = "awesome.dll",
				["Linux"] = "libawesome.so",
				["OSX"] = "libawesome.so",
				["BSD"] = "libawesome.so",
				["POSIX"] = "libawesome.so",
				["Other"] = "libawesome.so",
			}

			local standardizedLibraryName = C_BuildTools.GetSharedLibraryName(libraryBaseName)
			local expectedLibraryName = expectedLibraryNamesPerOS[ffi.os]
			assertEquals(standardizedLibraryName, expectedLibraryName)
		end)
	end)

	describe("GetExecutableName", function()
		it("should return a standardized executable name on all supported systems", function()
			local libraryBaseName = "notavirus"

			-- LuaJIT docs: Can only be "Windows", "Linux", "OSX", "BSD", "POSIX" or "Other"
			local expectedLibraryNamesPerOS = {
				["Windows"] = "notavirus.exe",
				["Linux"] = "notavirus",
				["OSX"] = "notavirus",
				["BSD"] = "notavirus",
				["POSIX"] = "notavirus",
				["Other"] = "notavirus",
			}

			local standardizedLibraryName = C_BuildTools.GetExecutableName(libraryBaseName)
			local expectedLibraryName = expectedLibraryNamesPerOS[ffi.os]
			assertEquals(standardizedLibraryName, expectedLibraryName)
		end)
	end)

	describe("GetOutputFromShellCommand", function()
		it("should return the process output in full when running a valid shell command", function()
			local command = "echo test"
			local expectedOutput = "test\n"
			local actualOutput = C_BuildTools.GetOutputFromShellCommand(command)
			assertEquals(actualOutput, expectedOutput)
		end)
	end)

	describe("DiscoverGitVersionTag", function()
		it("should return a single semantic version string", function()
			local gitVersionString = C_BuildTools.DiscoverGitVersionTag()
			assertString(gitVersionString)

			local semanticVersionString, major, minor, patch =
				string.match(gitVersionString, C_BuildTools.SEMANTIC_VERSION_STRING_PATTERN)
			assertString(semanticVersionString)
			assertString(major)
			assertString(minor)
			assertString(patch)
		end)
	end)

	describe("DiscoverPreviousGitVersionTag", function()
		it("should return a single semantic version string", function()
			local gitVersionString = C_BuildTools.DiscoverPreviousGitVersionTag()
			assertString(gitVersionString)

			print(gitVersionString)

			local semanticVersionString, major, minor, patch =
				string.match(gitVersionString, C_BuildTools.SEMANTIC_VERSION_STRING_PATTERN)
			assertString(semanticVersionString)
			assertString(major)
			assertString(minor)
			assertString(patch)
		end)
	end)

	describe("DiscoverCommitAuthorsBetween", function()
		it("should return all committers if two valid version tags are given", function()
			local oldVersionTag = "v3.0.0"
			local newVersionTag = "v3.1.0"
			local authors = C_BuildTools.DiscoverCommitAuthorsBetween(oldVersionTag, newVersionTag)

			-- Hardcoding these isn't great, but they aren't expected to ever change ("The history is immutable", yatta yatta)
			local expectedAuthors = C_BuildTools.PROJECT_AUTHORS
			assertEquals(authors, expectedAuthors)
		end)
	end)

	describe("DiscoverExternalContributorsBetween", function()
		it("should return all external committers if two valid version tags are given", function()
			local oldVersionTag = "v3.0.0"
			local newVersionTag = "v3.1.0"
			local authors = C_BuildTools.DiscoverExternalContributorsBetween(oldVersionTag, newVersionTag)

			-- Hardcoding these isn't great, but they aren't expected to ever change ("The history is immutable", yatta yatta)
			local expectedAuthors = {}
			assertEquals(authors, expectedAuthors)
		end)
	end)

	describe("DiscoverMergeCommitsBetween", function()
		it("should return an empty table if both version tags are identical", function()
			local versionTag = "v3.0.0"
			local commits = C_BuildTools.DiscoverMergeCommitsBetween(versionTag, versionTag)
			assertEquals(commits, {})
		end)

		it("should return all relevant merge commits if two valid version tags are given", function()
			local oldVersionTag = "v3.0.0"
			local newVersionTag = "v3.1.0"
			local commits = C_BuildTools.DiscoverMergeCommitsBetween(oldVersionTag, newVersionTag)

			-- Hardcoding these isn't great, but they aren't expected to ever change ("The history is immutable", yatta yatta)
			local expectedCommits = {
				"* \\[[`ce0ec6d`](https://github.com/evo-lua/evo-luvi/commit/ce0ec6d6b7cd3fe35144f1c720c95ef9747777d7)] - Add TCP_BACKPRESSURE related events to the TCP client and server builtins",
				"* \\[[`07e5b99`](https://github.com/evo-lua/evo-luvi/commit/07e5b9918a181b08cfc8db8e73e3019f479c72fe)] - Add a standardized way for handling empty EOF chunks to the TCP Socket builtins",
				"* \\[[`79ce363`](https://github.com/evo-lua/evo-luvi/commit/79ce3637a427018569138095d4a57abc12f15ea9)] - Refactor the luvi library exports",
				"* \\[[`2406b0a`](https://github.com/evo-lua/evo-luvi/commit/2406b0a22328de33e9db0dc83b11adac28f2c3db)] - Move the SIGPIPE handling code to LuaMain",
				"* \\[[`60a756d`](https://github.com/evo-lua/evo-luvi/commit/60a756d247e8b611e0e0f92075829a3f0766936d)] - Move the CLI spec to the Tests directory",
				"* \\[[`0938bce`](https://github.com/evo-lua/evo-luvi/commit/0938bcefdf8c3ed11d36f7e414e13329b3a46abc)] - Fix some incorrect API calls in the libuv socket mixins",
				"* \\[[`1232021`](https://github.com/evo-lua/evo-luvi/commit/1232021553b9678f3cd1a322d62cc2976a6c94ae)] - Add a global extend builtin to cut down on redundant OOP code",
				"* \\[[`36c6b72`](https://github.com/evo-lua/evo-luvi/commit/36c6b723b30dbdcfda30342dde78c1a05441da29)] - Add support for string buffers to the assertEquals builtin",
				"* \\[[`ab3663c`](https://github.com/evo-lua/evo-luvi/commit/ab3663cabbda7e4c5ca8c32b4f33f36cfa4100a8)] - Fix compilation warnings in the LPEG submodule",
				"* \\[[`bb70381`](https://github.com/evo-lua/evo-luvi/commit/bb70381316d7919e35f7d9c85eee8afb0898863d)] - Improve stack traces originating in main.c",
				"* \\[[`993caa9`](https://github.com/evo-lua/evo-luvi/commit/993caa985c3b80aa9457fd9ebf9be37d08c5c4a2)] - Enable the -g flag globally for generated LuaJIT bytecode objects",
				"* \\[[`7a621fc`](https://github.com/evo-lua/evo-luvi/commit/7a621fcf144d6678b279158421deb38d4be3893b)] - Add a generator script for the required llhttp-ffi C definitions",
				"* \\[[`155d033`](https://github.com/evo-lua/evo-luvi/commit/155d0332be7c3afd19548d792f603465de60f526)] - Reorganize the llhttp-ffi and llhttp submodules",
				"* \\[[`33787c9`](https://github.com/evo-lua/evo-luvi/commit/33787c916739e5bdfd69643a3600999f0af5c4b2)] - Integrate the llhttp-ffi submodule into the source tree",
				"* \\[[`a5e7b60`](https://github.com/evo-lua/evo-luvi/commit/a5e7b602fa664dc49e6b2b81567c0c52a68a6bd3)] - Update zlib build scripts to also copy zconf.h",
				"* \\[[`cfb4466`](https://github.com/evo-lua/evo-luvi/commit/cfb44669c41facc7e734213f1be5ddd9d0fe6cc0)] - Update the displayed executable name",
				"* \\[[`318d353`](https://github.com/evo-lua/evo-luvi/commit/318d3538203e37bbfba4db1618d011c99aa7cd67)] - Remove some unused CMake files",
				"* \\[[`b2b28b3`](https://github.com/evo-lua/evo-luvi/commit/b2b28b3d30ae6dc695216728e54ffa7688c2ca5b)] - Add a script for exporting the dependency graph",
				"* \\[[`9e437fb`](https://github.com/evo-lua/evo-luvi/commit/9e437fb1c405469c07e7cf5c2943cd60979f5f2f)] - Fix a typo in the unixbuild-all script",
				"* \\[[`0263f56`](https://github.com/evo-lua/evo-luvi/commit/0263f56ec0d78bfe60f8584c61f4586237342316)] - Remove the old PCRE1 repository from .gitmodules",
				"* \\[[`6c103e4`](https://github.com/evo-lua/evo-luvi/commit/6c103e4c3e1dbfa3fba7ff75be45bff860a284a4)] - Remove the broken luvi_renamed module",
				"* \\[[`3144d3e`](https://github.com/evo-lua/evo-luvi/commit/3144d3eb50aadbbb355930dfb7acafdf4df530f8)] - Add a basic test suite for the PCRE2 library",
				"* \\[[`f375f15`](https://github.com/evo-lua/evo-luvi/commit/f375f15aed8e5b83a42ea84193523cedf25bbf35)] - Add a basic smoke test for the zlib library",
				"* \\[[`ddd19dd`](https://github.com/evo-lua/evo-luvi/commit/ddd19dd4d600aca79f24d34b3d285b4f615c411b)] - Add a basic test for the luvi.version export",
			}
			assertEquals(commits, expectedCommits)
		end)
	end)

	describe("GetChangelogEntry", function()
		it("should return a table representing the markdown contents for a given version range", function()
			local changelog = require("changelog")
			local expectedChanges = changelog["v3.1.0"]

			local expectedChangelogEntry = {
				versionTag = "v3.1.0",
				newFeatures = expectedChanges.newFeatures or {},
				improvements = expectedChanges.improvements or {},
				breakingChanges = expectedChanges.breakingChanges or {},
				pullRequests = C_BuildTools.DiscoverMergeCommitsBetween("v3.0.0", "v3.1.0"),
				contributors = expectedChanges.contributors or {},
			}
			local actualChangelogEntry = C_BuildTools.GetChangelogEntry("v3.0.0", "v3.1.0")

			assertEquals(actualChangelogEntry, expectedChangelogEntry)
		end)
	end)

	describe("FetchNotableChanges", function()
		it("should return an empty table if a version tag without notable changes was given", function()
			local versionTag = "v2.18.0"
			local notableChanges = C_BuildTools.FetchNotableChanges(versionTag)

			assertEquals(notableChanges, {})
		end)

		it("should return a table of notable changes if there are any for the given version string", function()
			local versionTag = "v3.0.0"
			local notableChanges = C_BuildTools.FetchNotableChanges(versionTag)
			local expectedChanges = require("changelog")[versionTag]

			assertEquals(notableChanges, expectedChanges)
		end)
	end)

	describe("StringifyChangelogContents", function()
		it(
			"should return a markdown file without notable changes list if no changelog exists for the given version tag",
			function()
				local oldVersion = "v2.17.0"
				local newVersion = "v2.18.0"
				local changelogEntry = C_BuildTools.GetChangelogEntry(oldVersion, newVersion)

				local markdownString = C_BuildTools.StringifyChangelogContents(changelogEntry)

				local pullRequestString = C_BuildTools.DiscoverMergeCommitsBetween(oldVersion, newVersion)
				local expectedMarkdownString = [[
# v2.18.0

### Pull Requests

]] .. table.concat(pullRequestString, "\n") .. [[


#### Contributors (in alphabetical order)

* No external contributors]]
				assertEquals(markdownString, expectedMarkdownString)
			end
		)

		it(
			"should return a markdown file with notable changes list if a changelog exists for the given version tag",
			function()
				local oldVersion = "v3.0.0"
				local newVersion = "v3.1.0"
				local changelogEntry = C_BuildTools.GetChangelogEntry(oldVersion, newVersion)

				local markdownString = C_BuildTools.StringifyChangelogContents(changelogEntry)

				local pullRequestString = C_BuildTools.DiscoverMergeCommitsBetween(oldVersion, newVersion)
				local expectedMarkdownString = [[
# v3.1.0

### New Features

* A global ``extend`` builtin is now available to complement ``mixin`` with more typical, metatable-based inheritance

### Improvements

* TCP clients and servers now trigger ``TCP_BACKPRESSURE_*`` events based on their internal write buffer status
* TCP clients and servers now trigger ``TCP_EOF_RECEIVED`` when the connected peer unilaterally closes the socket
* The runtime now always includes debug symbols for embedded LuaJIT bytecode objects to enable better stack traces

### Breaking Changes

* The standalone [llhttp-ffi](https://github.com/evo-lua/llhttp-ffi) bindings are now integrated with the runtime itself (and will not be maintained independently)
* The preloaded ``luvi`` library is now called ``runtime`` and has a slightly different exports signature

### Pull Requests

]] .. table.concat(pullRequestString, "\n") .. [[


#### Contributors (in alphabetical order)

* No external contributors]]
				assertEquals(markdownString, expectedMarkdownString)
			end
		)
	end)

	describe("GenerateChangeLog", function()
		it("should save the last tagged version's changes to the changelog file", function()
			after(function()
				C_FileSystem.Delete("CHANGELOG.MD")
			end)

			local currentHead = C_BuildTools.DiscoverGitVersionTag()
			local lastVersionTag = C_BuildTools.DiscoverPreviousGitVersionTag()
			local expectedChanges = C_BuildTools.GetChangelogEntry(lastVersionTag, currentHead)
			local expectedMarkdownFileContents = C_BuildTools.StringifyChangelogContents(expectedChanges)

			C_BuildTools.GenerateChangeLog()

			local actualMarkdownFileContents = C_FileSystem.ReadFile("CHANGELOG.MD")

			assertEquals(actualMarkdownFileContents, expectedMarkdownFileContents)
		end)
	end)
end)
