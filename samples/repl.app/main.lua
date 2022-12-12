local uv = require("uv")
local bundle = require("runtime").bundle

local utils = loadstring(bundle:readfile("utils.lua"), "bundle:utils.lua")()
local repl = loadstring(bundle:readfile("repl.lua"), "bundle:repl.lua")()

local stdin = utils.stdin
local stdout = utils.stdout

local c = utils.color
local greeting = "Welcome to the " .. c("err") .. "L" .. c("quotes") .. "uv" .. c("table") .. "i" .. c() .. " repl!"
repl(stdin, stdout, uv, utils, greeting)

uv.run("default")
