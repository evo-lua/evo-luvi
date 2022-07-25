_G.format = string.format

local print = print
local function printf(...)
	return print(format(...))
end

_G.printf = printf
