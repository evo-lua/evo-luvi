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
	"143", -- accessing undefined field of global (likely a nonstandard extension)
	"212", -- unused argument 'self'; not a problem and commonly used for colon notation
	"213", -- unused loop variable (kept for readability's sake)
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

	-- Assertions
	"assertEquals",
	"assertFalse",
	"assertTrue",
	"assertFunctionCalls",
	"assertThrows",

	-- Bundle system
	"PosixFileSystemMixin",
	"ZipFileSystemMixin",

	-- Nonstandard primitives
	"dump",
	"format",
	"printf",
	"EVENT",
	"TEST",
	"DEBUG",
	"INFO",
	"NOTICE",
	"WARNING",
	"ERROR",
	"CRITICAL",
	"ALERT",
	"EMERGENCY",

	-- Nonstandard extensions
	"extend",
	"import",
	"mixin",
	"path",
	"utf8", -- Provided by lua-compat-5.3 when using 5.1/LuaJIT
	"transform",

	-- evo APIs
	"C_EventSystem",
	"C_FileSystem",
	"C_Networking",
	"C_Testing",
}
