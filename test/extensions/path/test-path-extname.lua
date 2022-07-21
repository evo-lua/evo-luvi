local path = _G.path

_G.currentNamespace = "any"
local testCases = {
	{ "test-path-extname.lua", ".lua" },
	{ "", "" },
	{ "/path/to/file", "" },
	{ "/path/to/file.ext", ".ext" },
	{ "/path.to/file.ext", ".ext" },
	{ "/path.to/file", "" },
	{ "/path.to/.file", "" },
	{ "/path.to/.file.ext", ".ext" },
	{ "/path/to/f.ext", ".ext" },
	{ "/path/to/..ext", ".ext" },
	{ "/path/to/..", "" },
	{ "file", "" },
	{ "file.ext", ".ext" },
	{ ".file", "" },
	{ ".file.ext", ".ext" },
	{ "/file", "" },
	{ "/file.ext", ".ext" },
	{ "/.file", "" },
	{ "/.file.ext", ".ext" },
	{ ".path/file.ext", ".ext" },
	{ "file.ext.ext", ".ext" },
	{ "file.", "." },
	{ ".", "" },
	{ "./", "" },
	{ ".file.ext", ".ext" },
	{ ".file", "" },
	{ ".file.", "." },
	{ ".file..", "." },
	{ "..", "" },
	{ "../", "" },
	{ "..file.ext", ".ext" },
	{ "..file", ".file" },
	{ "..file.", "." },
	{ "..file..", "." },
	{ "...", "." },
	{ "...ext", ".ext" },
	{ "....", "." },
	{ "file.ext/", ".ext" },
	{ "file.ext//", ".ext" },
	{ "file/", "" },
	{ "file//", "" },
	{ "file./", "." },
	{ "file.//", "." },
}

for index, testCase in ipairs(testCases) do
	local expected = testCase[2]
	local input = testCase[1]

	-- The behaviour should be identical for both Windows and POSIX systems
	_G.currentNamespace = "win32"
	local actual = path.win32.extname(input)
	assertStrictEqual(actual, expected, index)

	_G.currentNamespace = "posix"
	actual = path.posix.extname(input)
	assertStrictEqual(actual, expected, index)
end

-- On Windows, backslash is a path separator.
_G.currentNamespace = "win32"
assertStrictEqual(path.win32.extname(".\\"), "")
assertStrictEqual(path.win32.extname("..\\"), "")
assertStrictEqual(path.win32.extname("file.ext\\"), ".ext")
assertStrictEqual(path.win32.extname("file.ext\\\\"), ".ext")
assertStrictEqual(path.win32.extname("file\\"), "")
assertStrictEqual(path.win32.extname("file\\\\"), "")
assertStrictEqual(path.win32.extname("file.\\"), ".")
assertStrictEqual(path.win32.extname("file.\\\\"), ".")

-- On *nix, backslash is a valid name component like any other character.
_G.currentNamespace = "posix"
assertStrictEqual(path.posix.extname(".\\"), "")
assertStrictEqual(path.posix.extname("..\\"), ".\\")
assertStrictEqual(path.posix.extname("file.ext\\"), ".ext\\")
assertStrictEqual(path.posix.extname("file.ext\\\\"), ".ext\\\\")
assertStrictEqual(path.posix.extname("file\\"), "")
assertStrictEqual(path.posix.extname("file\\\\"), "")
assertStrictEqual(path.posix.extname("file.\\"), ".\\")
assertStrictEqual(path.posix.extname("file.\\\\"), ".\\\\")

print("OK\ttest-path-extname")
