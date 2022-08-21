local BytecodeGenerationRule = {}

function BytecodeGenerationRule:Construct()
	return {
		{ name = "command", "luajit", "-b", "$in", "$out", },
		{ name = "description", "Saving bytecode for", "$in" },
		{ name = "deps", "luajit" },
	}
end

BytecodeGenerationRule.__call = BytecodeGenerationRule.Construct
setmetatable(BytecodeGenerationRule, BytecodeGenerationRule)

return BytecodeGenerationRule