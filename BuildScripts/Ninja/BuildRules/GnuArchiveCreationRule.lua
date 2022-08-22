local GnuArchiveCreationRule = {}

function GnuArchiveCreationRule:Construct()
	return {
		{ name = "command", "ar", "crs", "$out", "$in"},
		{ name = "description", "Creating archive", "$out" },
	}
end

GnuArchiveCreationRule.__call = GnuArchiveCreationRule.Construct
setmetatable(GnuArchiveCreationRule, GnuArchiveCreationRule)

return GnuArchiveCreationRule