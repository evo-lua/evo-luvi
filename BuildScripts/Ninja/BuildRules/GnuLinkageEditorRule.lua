local GnuLinkageEditorRule = {}

function GnuLinkageEditorRule:Construct()
	return {
		{ name = "command", "gcc", "$in", "$libs", "-o", "$out" },
		{ name = "description", "Linking", "$in" },
	}
end

GnuLinkageEditorRule.__call = GnuLinkageEditorRule.Construct
setmetatable(GnuLinkageEditorRule, GnuLinkageEditorRule)

return GnuLinkageEditorRule