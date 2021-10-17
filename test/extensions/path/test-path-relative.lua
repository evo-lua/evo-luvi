local path = _G.path

local posixTestCases = {
    -- Arguments                     result
	{'/var/lib', '/var', '..'},
	{'/var/lib', '/bin', '../../bin'},
	{'/var/lib', '/var/lib', ''},
	{'/var/lib', '/var/apache', '../apache'},
	{'/var/', '/var/lib', 'lib'},
	{'/', '/var/lib', 'var/lib'},
	{'/foo/test', '/foo/test/bar/package.json', 'bar/package.json'},
	{'/Users/a/web/b/test/mails', '/Users/a/web/b', '../..'},
	{'/foo/bar/baz-quux', '/foo/bar/baz', '../baz'},
	{'/foo/bar/baz', '/foo/bar/baz-quux', '../baz-quux'},
	{'/baz-quux', '/baz', '../baz'},
	{'/baz', '/baz-quux', '../baz-quux'},
	{'/page1/page2/foo', '/', '../../..'},
}

local windowsTestCases ={
	{'c:/blah\\blah', 'd:/games', 'd:\\games'},
	{'c:/aaaa/bbbb', 'c:/aaaa', '..'},
	{'c:/aaaa/bbbb', 'c:/cccc', '..\\..\\cccc'},
	{'c:/aaaa/bbbb', 'c:/aaaa/bbbb', ''},
	{'c:/aaaa/bbbb', 'c:/aaaa/cccc', '..\\cccc'},
	{'c:/aaaa/', 'c:/aaaa/cccc', 'cccc'},
	{'c:/', 'c:\\aaaa\\bbbb', 'aaaa\\bbbb'},
	{'c:/aaaa/bbbb', 'd:\\', 'd:\\'},
	{'c:/AaAa/bbbb', 'c:/aaaa/bbbb', ''},
	{'c:/aaaaa/', 'c:/aaaa/cccc', '..\\aaaa\\cccc'},
	{'C:\\foo\\bar\\baz\\quux', 'C:\\', '..\\..\\..\\..'},
	{'C:\\foo\\test', 'C:\\foo\\test\\bar\\package.json', 'bar\\package.json'},
	{'C:\\foo\\bar\\baz-quux', 'C:\\foo\\bar\\baz', '..\\baz'},
	{'C:\\foo\\bar\\baz', 'C:\\foo\\bar\\baz-quux', '..\\baz-quux'},
	{'\\\\foo\\bar', '\\\\foo\\bar\\baz', 'baz'},
	{'\\\\foo\\bar\\baz', '\\\\foo\\bar', '..'},
	{'\\\\foo\\bar\\baz-quux', '\\\\foo\\bar\\baz', '..\\baz'},
	{'\\\\foo\\bar\\baz', '\\\\foo\\bar\\baz-quux', '..\\baz-quux'},
	{'C:\\baz-quux', 'C:\\baz', '..\\baz'},
	{'C:\\baz', 'C:\\baz-quux', '..\\baz-quux'},
	{'\\\\foo\\baz-quux', '\\\\foo\\baz', '..\\baz'},
	{'\\\\foo\\baz', '\\\\foo\\baz-quux', '..\\baz-quux'},
	{'C:\\baz', '\\\\foo\\bar\\baz', '\\\\foo\\bar\\baz'},
	{'\\\\foo\\bar\\baz', 'C:\\baz', 'C:\\baz'},
}

for index, testCase in ipairs(windowsTestCases) do
	local expected = testCase[3]
	local inputs = { testCase[1], testCase[2] }

	_G.currentNamespace = "win32"
	local actual = path.win32.relative(unpack(inputs))
	assertStrictEqual(actual, expected, index)
end

for index, testCase in ipairs(posixTestCases) do
	local expected = testCase[3]
	local inputs = { testCase[1], testCase[2] }

	_G.currentNamespace = "posix"
	actual = path.posix.relative(unpack(inputs))
	assertStrictEqual(actual, expected, index)
end

-- Relative, internally calls resolve. So, '' is actually the current directory
local uv = require("uv")
local pwd = uv.cwd()
assertStrictEqual(path.relative('', pwd), '')
assertStrictEqual(path.relative(pwd, ''), '')
assertStrictEqual(path.relative(pwd, pwd), '')

print("OK\ttest-path-relative")