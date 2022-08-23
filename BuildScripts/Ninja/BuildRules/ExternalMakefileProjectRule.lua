local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
	return {"command", "description",
	command=	{"cd", "$in", "&&", "make", "&&", "cd", "$cwd"},
description =			{ "Building external Makefile project", "$in" },
		}
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
