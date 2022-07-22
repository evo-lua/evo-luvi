local appArgs = { ... }
local args = table.concat(appArgs, "#")

return "HelloWorldZipApp/main.lua (vfs)" .. "#" .. args
