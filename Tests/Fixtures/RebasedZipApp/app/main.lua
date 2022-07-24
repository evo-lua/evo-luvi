local appArgs = { ... }
local args = table.concat(appArgs, "#")

return "RebasedZipApp/app/main.lua (vfs)" .. "#" .. args
