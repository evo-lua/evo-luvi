# Use this script to add all C and Lua sources as input for the build script
find Runtime -type f | grep ".lua" > BuildScripts/lua-sources.txt
# FFI bindings provided by dependencies aren't discovered by the simplistic find script
find deps/llhttp-ffi/llhttp.lua >> BuildScripts/lua-sources.txt

find Runtime -type f | grep ".c" > BuildScripts/c-sources.txt
