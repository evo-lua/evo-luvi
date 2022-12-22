local versionFrom, versionTo = ...

local C_BuildTools = import("Runtime/API/BuildTools/C_BuildTools.lua")

C_BuildTools.GenerateChangeLog(versionFrom, versionTo)
