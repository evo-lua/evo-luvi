local GnuLinkageEditorRule = {}

function GnuLinkageEditorRule:Construct()
	return { "command", "description",
		command = { "gcc", "$in", "$libs", "-o", "$out" },
		description = { "Linking", "$in" },
	}
end

GnuLinkageEditorRule.__call = GnuLinkageEditorRule.Construct
setmetatable(GnuLinkageEditorRule, GnuLinkageEditorRule)

return GnuLinkageEditorRule