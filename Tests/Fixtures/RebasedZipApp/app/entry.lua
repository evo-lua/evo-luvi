local appArgs = { ... }
local args = table.concat(appArgs, "#")

return "RebasedZipApp/app/entry.lua (vfs)" .. "#" .. args
