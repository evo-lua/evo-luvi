local luvibundle = require("luvibundle")

local LuviAppBundle = {
	DEFAULT_ENTRY_POINT = "main.lua",
}

function LuviAppBundle:Construct(appPath, entryPoint)
	local instance = {
		path = appPath,
		entryPoint = entryPoint or LuviAppBundle.DEFAULT_ENTRY_POINT
	}

	setmetatable(instance, { __index = LuviAppBundle })

	return instance
end

setmetatable(LuviAppBundle, {
	__call = LuviAppBundle.Construct
})

function LuviAppBundle:RunContainedApp(commandLineArguments)
	return luvibundle.commonBundle(self.path, self.entryPoint, commandLineArguments)
end

function LuviAppBundle:CreateZipApp(outputPath)
	return luvibundle.buildBundle(outputPath, luvibundle.makeBundle(self.path))
end

return LuviAppBundle