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
	"143", -- accessing undefined field of global; busted does this and I can't change it
	"212", -- unused argument 'self'; not a problem and commonly used for colon notation
}
globals = {
	-- busted (Test runner)
	"describe",
	"it",
	"setup",
	"teardown",

	-- Nonstandard extensions
	"import",
	"path",

	-- evo APIs
	"C_Testing",
}
