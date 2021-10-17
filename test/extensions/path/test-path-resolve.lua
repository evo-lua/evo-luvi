local path = _G.path

local ffi = require("ffi")
local uv = require("uv")

-- JavaScript is truly a thing of beauty...
local posixyCwd = ffi.os == "Windows" and
 (function()
    local _ = uv.cwd():gsub(path.separator, path.posix.separator)
	local posixPath = _:sub(_:find(path.posix.separator), #_)
    return posixPath
 end)()
  or
  process.cwd()

local uv = require("uv")

local function getCurrentDeviceRoot()
	local cwd = uv.cwd()
	-- It's always an absolute path, which on windows starts with a disk designator (letter and colon)
	return cwd:sub(1, 2)
end

local windowsTestCases = {
    -- Arguments                               result
    {{'c:/blah\\blah', 'd:/games', 'c:../a'}, 'c:\\blah\\a'},
     {{'c:/ignore', 'd:\\a/b\\c/d', '\\e.exe'}, 'd:\\e.exe'}, -- d is the last drive visited, so stay on there. network paths do not change the current drive
     {{'c:/ignore', 'c:/some/file'}, 'c:\\some\\file'}, -- cd in same drive means the second command overrides the first
     {{'d:/ignore', 'd:some/dir//'}, 'd:\\ignore\\some\\dir'}, -- d: is invalid drive identifier, so it should be skipped
     {{'.'}, uv.cwd()}, -- cwd is resolved properly
     {{'//server/share', '..', 'relative\\'}, '\\\\server\\share\\relative'},
     {{'c:/', '//'}, 'c:\\'},
     {{'c:/', '//dir'}, 'c:\\dir'},
     {{'c:/', '//server/share'}, '\\\\server\\share\\'},
     {{'c:/', '//server//share'}, '\\\\server\\share\\'},
     {{'c:/', '///some//dir'}, 'c:\\some\\dir'},
     {{'C:\\foo\\tmp.3\\', '..\\tmp.3\\cycles\\root.js'},
      'C:\\foo\\tmp.3\\cycles\\root.js'},
	  -- Custom tests (since the NodeJS ones don't seem to exercise all code paths, for some reason)
	  { {"ignore/dir"}, uv.cwd() .. "\\ignore\\dir" }, -- relative path resolution should use the current drive's cwd
	  { {"ignore", "", "/dir"}, getCurrentDeviceRoot() .. "\\dir" } -- empty path segments should be ignored
}

local posixTestCases = {
    -- Arguments                    result
    {{'/var/lib', '../', 'file/'}, '/var/file'},
     {{'/var/lib', '/../', 'file/'}, '/file'},
     {{'a/b/c/', '../../..'}, posixyCwd}, -- TBD: Use WSL-style path resolution for cwd instead?
     {{'.'}, posixyCwd},
     {{'/some/dir', '.', '/absolute/'}, '/absolute'},
     {{'/foo/tmp.3/', '../tmp.3/cycles/root.js'}, '/foo/tmp.3/cycles/root.js'},
}

for index, testCase in ipairs(windowsTestCases) do

	local expected = testCase[2]
	local inputs = testCase[1]

	-- The behaviour should be identical for both Windows and POSIX systems
	_G.currentNamespace = "win32"
	local actual = path.win32.resolve(unpack(inputs))
	assertStrictEqual(actual, expected, index)
end


for index, testCase in ipairs(posixTestCases) do

	local expected = testCase[2]
	local inputs = testCase[1]

	_G.currentNamespace = "posix"
	actual = path.posix.resolve(unpack(inputs))
	assertStrictEqual(actual, expected, index)
end

-- Resolve, internally ignores all the zero-length strings and returns the
-- current working directory
local pwd = uv.cwd()
assertStrictEqual(path.resolve(''), pwd)
assertStrictEqual(path.resolve('', ''), pwd)

print("OK\ttest-path-resolve")