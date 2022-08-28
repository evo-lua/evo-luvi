local GnuCompilerCollection = {}

function GnuCompilerCollection:Construct()
	local instance = {}
	instance.__index = self
	setmetatable(instance, instance)
	return instance
end

function GnuCompilerCollection:GetCompileCommand()
	return { "command", "description", "depfile", "deps",
	command = { "gcc", "-MMD", "-MT", "$out", "-MF", "$out.d", "-c", "$in", "$includes", "-o", "$out" },
	description =	{"Compiling", "$in" },
	depfile =	{ "$out.d" },
	deps =	{ "gcc" },
	}
end

GnuCompilerCollection.__call = GnuCompilerCollection.Construct
setmetatable(GnuCompilerCollection, GnuCompilerCollection)

return GnuCompilerCollection
