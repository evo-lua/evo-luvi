-- Upvalues
local assertStrictEqual = assertStrictEqual
local type = type
local tostring = tostring
local pairs = pairs
local ipairs = ipairs
local dofile = dofile
local require = require

local ffi = require("ffi")

-- Tests for the path library implementation (ported from NodeJS)
local path = _G.path

-- Basic smoke tests
assertStrictEqual(type(path.win32), "table", "The win32 path library must exist")
assertStrictEqual(type(path.posix), "table", "The posix path library must exist")

-- Default to the detected OS convention
if ffi.os == "Windows" then
	assertStrictEqual(path.convention, "Windows", "Should default to Windows path library on Windows systems")
	assertStrictEqual(path, path.win32, "The Path API must be using path.win32 on Windows")
else
	assertStrictEqual(path.convention, "POSIX", "Should default to POSIX path library on non-Windows systems")
	assertStrictEqual(path, path.posix, "The Path API must be using path.posix on POSIX-compliant platforms")
end

-- Type errors: Only strings are valid paths(* excluding optional args)
local invalidTypeValues = {true, false, 7, nil, {}, 42.0}

local function assertFailure(func, ...)
    local result, errorMessage = func(...)
    -- invalid types should return nil and error (Lua style), not errors (JavaScript style)
    assertStrictEqual(result, nil, "result is not nil")
    assertStrictEqual(type(errorMessage), "string", "message must be a string: " .. tostring(errorMessage))
    assertStrictEqual(errorMessage:find("Usage: "), 1, "message must be 'Usage: ..., actual: " .. tostring(errorMessage) .. "'")
end

local functionsToTest = {
	"join",
	"resolve",
	"normalize",
	"isAbsolute",
	"relative",
	"dirname",
	"basename",
	"extname",
}

for key, value in pairs(invalidTypeValues) do
    for name, namespace in pairs( { win32 = path.win32, posix = path.posix}) do
		for index, func in ipairs(functionsToTest) do
			print("Basic input validation test: " .. name .. "." .. func .. " (input: " .. tostring(value) .. ")")
			assertFailure(namespace[func], value)
		end

		-- These don't really fit the pattern, so just add them manually
		assertFailure(namespace.relative, value, 'foo')
        assertFailure(namespace.relative, 'foo', value)

		print("Completed basic input validation tests for namespace: " .. name)
    end
end

-- Path separators and delimiters should be consistent with the respective OS' convention
assertStrictEqual(path.win32.separator, '\\', "Windows path separator must be BACKSLASH")
assertStrictEqual(path.posix.separator, '/', "POSIX path separator must be FORWARD_SLASH")
assertStrictEqual(path.win32.delimiter, ';', "Windows path delimiter must be SEMICOLON")
assertStrictEqual(path.posix.delimiter, ':', "POSIX path delimiter must be COLON")

dofile("test/extensions/path/test-path-dirname.lua")
dofile("test/extensions/path/test-path-basename.lua")
dofile("test/extensions/path/test-path-isabsolute.lua")
dofile("test/extensions/path/test-path-normalize.lua")
dofile("test/extensions/path/test-path-extname.lua")
dofile("test/extensions/path/test-path-resolve.lua")
dofile("test/extensions/path/test-path-join.lua")
dofile("test/extensions/path/test-path-relative.lua")
