local GnuCompilerCollectionRule = {}

function GnuCompilerCollectionRule:Construct()
	return {
		{ name = "command", "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "$include_dirs", "-o", "$out" },
		{ name = "description", "Compiling", "$in" },
		{ name = "depfile", "$out.d" },
		{ name = "deps", "gcc" },
	}
end

GnuCompilerCollectionRule.__call = GnuCompilerCollectionRule.Construct
setmetatable(GnuCompilerCollectionRule, GnuCompilerCollectionRule)

return GnuCompilerCollectionRule