local appArgs = { ... }
local args = table.concat(appArgs, "#")

return "HelloWorldZipApp/entry.lua (vfs)" .. "#" .. args
