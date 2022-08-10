-- trace calls
-- example: lua -ltrace-calls bisect.lua

-- local level=0

-- local function hook(event)
--  local t=debug.getinfo(3)
--  io.write(level," >>> ",string.rep(" ",level))
--  if t~=nil and t.currentline>=0 then io.write(t.short_src,":",t.currentline," ") end
--  t=debug.getinfo(2)
--  if event=="call" then
--   level=level+1
--  else
--   level=level-1 if level<0 then level=0 end
--  end
--  if t.what=="main" then
--   if event=="call" then
--    io.write("begin ",t.short_src)
--   else
--    io.write("end ",t.short_src)
--   end
--  elseif t.what=="Lua" then
--   io.write(event," ",t.name or "(Lua)"," <",t.linedefined,":",t.short_src,">")
--  else
--  io.write(event," ",t.name or "(C)"," [",t.what,"] ")
--  end
--  io.write("\n")
-- end

-- debug.sethook(hook,"cr")
-- level=0

-- function trace (event, line)
-- 	local s = debug.getinfo(2).short_src
-- 	print(s .. ":" .. line)
--   end

--   debug.sethook(trace, "l")

-- Acceptance tests (below) use a more verbose format and should only be used for use case scenarios
local testSuites = {
	"Tests/Runtime/API/Networking/networking-scenarios.lua",
}

for _, filePath in pairs(testSuites) do
	local testSuite = import(filePath)
	-- For CI pipelines and scripts, ensure the return code indicates EXIT_FAILURE if at least one assertion has failed
	assert(testSuite:Run(), "Assertion failure in test suite " .. filePath)
end
