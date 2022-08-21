local llhttp = import("./BuildScripts/Targets/llhttp.lua")

local llhttpBuildFile = llhttp:CreateBuildFile()
llhttpBuildFile:Save("llhttp_test.ninja")