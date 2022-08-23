local ExternalMakefileProjectRule = {}

function ExternalMakefileProjectRule:Construct()
	return {"command", "description",
				-- TODO bash on unix/osx
	command=	{"cmd", "/c", "cd", "$in", "&&", "make", "&&", "cd", "$cwd"},
description =			{ "Building external Makefile project", "$in" },
		}
end

ExternalMakefileProjectRule.__call = ExternalMakefileProjectRule.Construct
setmetatable(ExternalMakefileProjectRule, ExternalMakefileProjectRule)

return ExternalMakefileProjectRule
