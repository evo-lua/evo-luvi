local pairs = pairs
local type = type

local function copyFunctionsFromMixin(target, mixin)
	if  type(target) ~= "table" then
		return
	end

	if  type(mixin) ~= "table" then
		return
	end

	for key, value in pairs(mixin) do
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