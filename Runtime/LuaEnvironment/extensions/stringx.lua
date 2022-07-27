local string_sub = string.sub
local math_max = math.max

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
