local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
	return {"command", "description",
	command=	{"cd", "$in", "&&", "make", "&&", "cd", "$cwd"},
description =			{ "External Makefile build in directory", "$in" },
		}
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
