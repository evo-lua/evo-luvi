std = "lua51"
max_line_length = false
exclude_files = {
	"luacheckrc",
	"build/",
	"deps/",
	"samples/",
	"test/",
	"**/path.lua", -- Not much hope here; this is ported spaghetti code from NodeJS
}
ignore = {
	"212", -- unused argument 'self'; not a problem and commonly used for colon notation
}
globals = {
	-- Test runner
	"describe",
	"it",
	"before",
	"after",
	"assertEquals",
	"assertFalse",
	"assertThrows",

	-- Bundle system
	"PosixFileSystemMixin",
	"ZipFileSystemMixin",

	-- Nonstandard extensions
	"import",
	"mixin",
	"path",

	-- evo APIs
	"C_Testing",
}
