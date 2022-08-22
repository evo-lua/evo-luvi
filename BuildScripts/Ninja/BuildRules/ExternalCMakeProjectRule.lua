local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
	return {"command", "description",
	command ={ "cmake", "--build", "$out"},
	description = {"External CMake build in directory", "$out" },
		}
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
