local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
	return {
			{ name = "command", "cd", "$in", "&&", "make", "&&", "cd", "&&", "$cwd"},
			{ name = "description", "External Makefile build in directory", "$out" },
		}
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
