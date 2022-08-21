local GnuCompilerCollection = {}

function GnuCompilerCollection:Construct()
	return {
		{ name = "command", "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "-o", "$out" },
		{ name = "description", "CC", "$out" },
		{ name = "depfile", "$out.d" },
		{ name = "deps", "gcc" },
	}
end

GnuCompilerCollection.__call = GnuCompilerCollection.Construct
setmetatable(GnuCompilerCollection, GnuCompilerCollection)

return GnuCompilerCollection