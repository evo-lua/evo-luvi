local NINJA_BUILD_DIR = "ninjabuild"
local DEFAULT_BUILD_FILE = "build.ninja"

local path_join = path.join

local externalBuildTargets = {
	"llhttp",
}

print("Processing build configuration for external projects...")

local function CreateNinjaBuildFile(targetID)
	printf("Creating build file for target: %s", targetID)

	local target = import("./BuildScripts/Targets/" .. targetID)
	local buildFile = target:CreateBuildFile()

	local outputFilePath = path_join(NINJA_BUILD_DIR, targetID .. ".ninja")
	if targetID == "evo" then
		-- This is the name ninja will default to, so let's use it to make building more convenient
		outputFilePath = path_join(NINJA_BUILD_DIR, DEFAULT_BUILD_FILE)
	end
	buildFile:Save(outputFilePath)
	printf("-> Configuration saved as %s", outputFilePath)
end

for index, targetID in ipairs(externalBuildTargets) do
	CreateNinjaBuildFile(targetID)
end

print("Processing build configuration...")
CreateNinjaBuildFile("evo")

printf("All done! To build the runtime, type %s", transform.green("ninja -C ninjabuild"))