local GnuCompilerCollectionRule = {}

function GnuCompilerCollectionRule:Construct()
	return { "command", "description", "depfile", "deps",
	command = { "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "$includes", "-o", "$out" },
	description =	{"Compiling", "$in" },
	depfile =	{ "$out.d" },
	deps =	{ "gcc" },
	}
end

GnuCompilerCollectionRule.__call = GnuCompilerCollectionRule.Construct
setmetatable(GnuCompilerCollectionRule, GnuCompilerCollectionRule)

return GnuCompilerCollectionRule