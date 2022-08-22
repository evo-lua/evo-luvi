local GnuArchiveCreationRule = {}

function GnuArchiveCreationRule:Construct()
	return {"command", "description",
	command={"ar", "crs", "$out", "$in"},
	description = { "Creating archive", "$out" },
	}
end

GnuArchiveCreationRule.__call = GnuArchiveCreationRule.Construct
setmetatable(GnuArchiveCreationRule, GnuArchiveCreationRule)

return GnuArchiveCreationRule