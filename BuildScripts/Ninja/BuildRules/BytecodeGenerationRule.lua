local BytecodeGenerationRule = {}

function BytecodeGenerationRule:Construct()
	return {"command", "description", "deps",
		command = { "luajit", "-b", "$in", "$out", }, -- TODO preprend $jitdir
		description = { "Saving bytecode for", "$in" },
		deps = { "luajit" }, -- TODO preprend $jitdir
	}
end

BytecodeGenerationRule.__call = BytecodeGenerationRule.Construct
setmetatable(BytecodeGenerationRule, BytecodeGenerationRule)

return BytecodeGenerationRule