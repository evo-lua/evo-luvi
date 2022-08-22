local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
	return {
			{ name = "command", "cmake", "--build", "$out"},
			{ name = "description", "External CMake build in directory", "$out" },
		}
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
