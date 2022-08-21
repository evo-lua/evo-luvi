local NINJA_BUILD_DIR = "ninjabuild"

local path_join = path.join

local externalBuildTargets = {
	"llhttp",
}

print("Processing build configuration for external targets...")

for index, targetID in ipairs(externalBuildTargets) do
	printf("Creating build file for target: %s", targetID)

	local target = import("./BuildScripts/Targets/" .. targetID)
	local buildFile = target:CreateBuildFile()

	local outputFilePath = path_join(NINJA_BUILD_DIR, targetID .. ".ninja")
	buildFile:Save(outputFilePath)
	printf("-> Configuration saved as %s", outputFilePath)
end

printf("All done! To build the runtime, type %s", transform.green("ninja -C ninjabuild"))