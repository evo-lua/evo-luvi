local path = _G.path

_G.currentNamespace = "any"

local __filename = "test-path-basename.js"

assertStrictEqual(path.basename(__filename), 'test-path-basename.js')
assertStrictEqual(path.basename(__filename, '.js'), 'test-path-basename')
assertStrictEqual(path.basename('.js', '.js'), '')
assertStrictEqual(path.basename(''), '')
assertStrictEqual(path.basename('/dir/basename.ext'), 'basename.ext')
assertStrictEqual(path.basename('/basename.ext'), 'basename.ext')
assertStrictEqual(path.basename('basename.ext'), 'basename.ext')
assertStrictEqual(path.basename('basename.ext/'), 'basename.ext')
assertStrictEqual(path.basename('basename.ext//'), 'basename.ext')
assertStrictEqual(path.basename('aaa/bbb', '/bbb'), 'bbb')
assertStrictEqual(path.basename('aaa/bbb', 'a/bbb'), 'bbb')
assertStrictEqual(path.basename('aaa/bbb', 'bbb'), 'bbb')
assertStrictEqual(path.basename('aaa/bbb//', 'bbb'), 'bbb') -- WIP
assertStrictEqual(path.basename('aaa/bbb', 'bb'), 'b')
assertStrictEqual(path.basename('aaa/bbb', 'b'), 'bb')
assertStrictEqual(path.basename('/aaa/bbb', '/bbb'), 'bbb')
assertStrictEqual(path.basename('/aaa/bbb', 'a/bbb'), 'bbb')
assertStrictEqual(path.basename('/aaa/bbb', 'bbb'), 'bbb')
assertStrictEqual(path.basename('/aaa/bbb//', 'bbb'), 'bbb')
assertStrictEqual(path.basename('/aaa/bbb', 'bb'), 'b')
assertStrictEqual(path.basename('/aaa/bbb', 'b'), 'bb')
assertStrictEqual(path.basename('/aaa/bbb'), 'bbb')
assertStrictEqual(path.basename('/aaa/'), 'aaa')
assertStrictEqual(path.basename('/aaa/b'), 'b')
assertStrictEqual(path.basename('/a/b'), 'b')
assertStrictEqual(path.basename('//a'), 'a')
assertStrictEqual(path.basename('a', 'a'), '')

-- On Windows a backslash acts as a path separator.
_G.currentNamespace = "win32"
assertStrictEqual(path.win32.basename('\\dir\\basename.ext'), 'basename.ext')
assertStrictEqual(path.win32.basename('\\basename.ext'), 'basename.ext')
assertStrictEqual(path.win32.basename('basename.ext'), 'basename.ext')
assertStrictEqual(path.win32.basename('basename.ext\\'), 'basename.ext')
assertStrictEqual(path.win32.basename('basename.ext\\\\'), 'basename.ext')
assertStrictEqual(path.win32.basename('foo'), 'foo')
assertStrictEqual(path.win32.basename('aaa\\bbb', '\\bbb'), 'bbb')
assertStrictEqual(path.win32.basename('aaa\\bbb', 'a\\bbb'), 'bbb')
assertStrictEqual(path.win32.basename('aaa\\bbb', 'bbb'), 'bbb')
assertStrictEqual(path.win32.basename('aaa\\bbb\\\\\\\\', 'bbb'), 'bbb')
assertStrictEqual(path.win32.basename('aaa\\bbb', 'bb'), 'b')
assertStrictEqual(path.win32.basename('aaa\\bbb', 'b'), 'bb')
assertStrictEqual(path.win32.basename('C:'), '')
assertStrictEqual(path.win32.basename('C:.'), '.')
assertStrictEqual(path.win32.basename('C:\\'), '')
assertStrictEqual(path.win32.basename('C:\\dir\\base.ext'), 'base.ext')
assertStrictEqual(path.win32.basename('C:\\basename.ext'), 'basename.ext')
assertStrictEqual(path.win32.basename('C:basename.ext'), 'basename.ext')
assertStrictEqual(path.win32.basename('C:basename.ext\\'), 'basename.ext')
assertStrictEqual(path.win32.basename('C:basename.ext\\\\'), 'basename.ext')
assertStrictEqual(path.win32.basename('C:foo'), 'foo')
assertStrictEqual(path.win32.basename('file:stream'), 'file:stream')
assertStrictEqual(path.win32.basename('a', 'a'), '')

-- On unix a backslash is just treated as any other character.
_G.currentNamespace = "posix"
assertStrictEqual(path.posix.basename('\\dir\\basename.ext'), '\\dir\\basename.ext')
assertStrictEqual(path.posix.basename('\\basename.ext'), '\\basename.ext')
assertStrictEqual(path.posix.basename('basename.ext'), 'basename.ext')
assertStrictEqual(path.posix.basename('basename.ext\\'), 'basename.ext\\')
assertStrictEqual(path.posix.basename('basename.ext\\\\'), 'basename.ext\\\\')
assertStrictEqual(path.posix.basename('foo'), 'foo')

-- POSIX filenames may include control characters
-- c.f. http://www.dwheeler.com/essays/fixing-unix-linux-filenames.html
local controlCharFilename = string.format("Icon%s", string.char(13))
assertStrictEqual(path.posix.basename(string.format("/a/b/%s", controlCharFilename)), controlCharFilename)

print("OK\ttest-path-basename")