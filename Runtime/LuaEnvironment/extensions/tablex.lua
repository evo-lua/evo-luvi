local pairs = pairs
local type = type

function _G.table.count(object)
	local count = 0
	for k, v in pairs(object) do
		-- cdata can trip up nil checks, so it's best to be explicit here
		if type(v) ~= "nil" then
			count = count + 1
		end
	end
	return count
end
