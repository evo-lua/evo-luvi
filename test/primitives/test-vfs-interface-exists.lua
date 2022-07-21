local vfs = require("virtual_file_system")

assertStrictEqual(type(vfs.hasFile), "function", "vfs.hasFile is a function")
assertStrictEqual(type(vfs.hasFolder), "function", "vfs.hasFolder is a function")
assertStrictEqual(type(vfs.loadFile), "function", "vfs.loadFile is a function")
