local string_sub = string.sub
local math_max = math.max
local string_gmatch = string.gmatch
local table_insert = table.insert
local type = type

function _G.string.diff(before, after)
	local maxIndexToCheck = math_max(#before, #after)
	local lastNewlineIndex
	local numCharsSinceLastNewline = 0

	for index = 1, maxIndexToCheck, 1 do
		local charAt = string_sub(before, index, index)
		local charAtDiff = string_sub(after, index, index)

		-- Move index BEFORE the evaluation to ensure it always refers to the first non-matching character
		if charAt == "\n" then
			lastNewlineIndex = index
		end

		if not charAt or not charAtDiff or (charAt ~= charAtDiff) then
			return index, lastNewlineIndex, numCharsSinceLastNewline
		end

		-- Move cursor only AFTER the evaluation so ensure it stops in front of the last matching character
		if charAt ~= "\n" then
			numCharsSinceLastNewline = numCharsSinceLastNewline + 1
		else
			numCharsSinceLastNewline = 0
		end
	end
end

function _G.string.explode(inputString, delimiter)
	if type(inputString) ~= "string" then
		error("Usage: explode(inputString : string, delimiter : string?)", 0)
	end

	delimiter = delimiter or "%s" -- Use whitespace by default

	local tokens = {}
	for token in string_gmatch(inputString, "([^" .. delimiter .. "]+)") do
		table_insert(tokens, token)
	end
	return tokens
end
