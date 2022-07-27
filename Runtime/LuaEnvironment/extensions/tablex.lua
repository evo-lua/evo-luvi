local dump = dump
local pairs = pairs
local string_diff = string.diff
local string_rep = string.rep
local string_sub = string.sub
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

function _G.table.diff(before, after)
	if type(before) ~= "table" or type(after) ~= "table" then
		error("Usage: diff(before : table, after : table)", 0)
	end

	local diffString = ""

	local beforeString = dump(before, { silent = true })
	local afterString = dump(after, { silent = true })

	-- Early exit to avoid unnecessary computation
	if beforeString == afterString then
		return ""
	end

	-- Compute surrounding lines from the given index
	local firstDifferingIndex, _, numCharsSinceLastNewline = string_diff(beforeString, afterString)
	local startString = string_sub(beforeString, 1, firstDifferingIndex)
	local endString = string_sub(beforeString, firstDifferingIndex + 1)

	diffString = diffString .. "--------------------" .. "\n"
	diffString = diffString .. startString .. ""
	diffString = diffString .. endString .. "\n"

	diffString = diffString .. "--------------------" .. "\n"

	startString = string_sub(afterString, 1, firstDifferingIndex)
	endString = string_sub(afterString, firstDifferingIndex + 1)
	diffString = diffString .. startString .. "\n"
	diffString = diffString
		.. string_rep(" ", numCharsSinceLastNewline)
		.. transform.brightRed("^ THERE BE A MISMATCH HERE") -- Can't upvalue other extensions (load order)
	diffString = diffString .. endString .. "\n"
	diffString = diffString .. "--------------------"

	return diffString
end
