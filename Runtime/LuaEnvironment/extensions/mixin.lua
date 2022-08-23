local pairs = pairs
local type = type

local table_clone

table_clone = function (source)
	local copy = {}
	for k, v in pairs(source) do
		if type(v) ~= "table" then
			copy[k] = v
		else
			copy[k] = table_clone(v)
		end
	end
	return copy
end

local function copyFunctionsFromMixin(target, mixin)
	if type(target) ~= "table" then
		return
	end

	if type(mixin) ~= "table" then
		return
	end

	for key, value in pairs(mixin) do
		if type(value) == "table" and target[key] == nil then
			target[key] = table_clone(value)
		end

		if type(value) == "function" and target[key] == nil then
			target[key] = value
		end
	end
end

local function mixin(target, ...)
	local tablesToMixIn = { ... }

	for _, sourceMixin in pairs(tablesToMixIn) do
		copyFunctionsFromMixin(target, sourceMixin)
	end
end

return mixin
