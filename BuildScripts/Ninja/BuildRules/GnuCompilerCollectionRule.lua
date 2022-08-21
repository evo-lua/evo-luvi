local GnuCompilerCollectionRule = {}

function GnuCompilerCollectionRule:Construct()
	return {
		{ name = "command", "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "-o", "$out" },
		{ name = "description", "CC", "$out" },
		{ name = "depfile", "$out.d" },
		{ name = "deps", "gcc" },
	}
end

GnuCompilerCollectionRule.__call = GnuCompilerCollectionRule.Construct
setmetatable(GnuCompilerCollectionRule, GnuCompilerCollectionRule)

return GnuCompilerCollectionRule