local appArgs = { ... }
local args = table.concat(appArgs, "#")

return "HelloWorldApp/main.lua (disk)" .. "#" .. args
