local appArgs = { ... }
local args = table.concat(appArgs, "#")

return "HelloWorldApp/entry.lua (disk)" .. "#" .. args
