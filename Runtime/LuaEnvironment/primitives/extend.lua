local getmetatable = getmetatable
local setmetatable = setmetatable
local pairs = pairs
local type = type

local function extend(child, parent)
	local parentMetatable = getmetatable(parent)

	if type(parentMetatable) ~= "table" then
		setmetatable(parent, {})
		parentMetatable = getmetatable(parent)
	end

	local childMetatable = {}
	for key, value in pairs(parentMetatable) do
		childMetatable[key] = value
	end

	childMetatable.__index = parent

	setmetatable(child, childMetatable)
end

_G.extend = extend
