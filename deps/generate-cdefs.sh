echo "Generating cleaned-up cdefs from llhttp.h"

LLHTTP_DIR=deps/llhttp
CPARSER=deps/cparser/lcpp
# LuaJIT will falsely interpret it as a binary by default ...
cp $CPARSER $CPARSER.lua

# ffi.cdef() cannot process preprocessor directives, so strip them first
ninjabuild-unix/luajit $CPARSER $LLHTTP_DIR/include/llhttp.h -o llhttp_preprocessed.h 
grep "^[^#;]" llhttp_preprocessed.h > deps/llhttp_cdefs.h

# Don't leave clutter behind as it might confuse git
rm llhttp_preprocessed.h
rm $CPARSER.lua
