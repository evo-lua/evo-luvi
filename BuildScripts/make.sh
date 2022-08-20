# Run this script from the project's root directory in order to build the runtime as an executable
# Prerequisites: make, gcc, cmake
# set -x # Uncomment for easier debugging (verbose output)
set -e

PROJECT_ROOT=$(pwd)
LUA_SOURCES_LIST=$PROJECT_ROOT/BuildScripts/lua-sources.txt
C_SOURCES_LIST=$PROJECT_ROOT/BuildScripts/c-sources.txt

COMPILE_COMMAND="gcc -Wl,-E -Werror -O3"

# Prepare dependencies (using whatever build system they ship with)

## luajit (TBD use the one built by libluv?)
LUAJIT_DIR=$PROJECT_ROOT/deps/luv/deps/luajit
LUAJIT_TARGET="$LUAJIT_DIR/src/libluajit.a"

echo "Building target: libluajit.a"
cd $LUAJIT_DIR
make

cd $PROJECT_ROOT

## luv
echo "Building target: libluv.a"
LUV_DIR="$PROJECT_ROOT/deps/luv"
cd $LUV_DIR
cmake -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF . && cmake --build .
cd $PROJECT_ROOT

## llhttp
LLHTTP_DIR="$PROJECT_ROOT/deps/llhttp-ffi/llhttp"
LLHTTP_INCLUDE_DIR="include"
LLHTTP_INPUT="$LLHTTP_DIR/src/api.c $LLHTTP_DIR/src/http.c $LLHTTP_DIR/src/llhttp.c"
LLHTTP_OUTPUT="libllhttp.a"
echo "Building target: libllhttp.a"

cd $LLHTTP_DIR
cmake -DBUILD_STATIC_LIBS=ON -DBUILD_SHARED_LIBS=OFF . && cmake --build .
cd $PROJECT_ROOT

# lua-compat-5.3
COMPAT_DIR="$PROJECT_ROOT/deps/luv/deps/lua-compat-5.3" # Linked with libluv_a, we only need the headers


## openssl + asm optimizations

# zlib?

#pcre?

# lpeg?

# lrexlib?


## Embed scripts as bytecode (so they can be loaded via LuaJIT's require mechanism)
export LUA_PATH="$LUAJIT_DIR/src/?;$LUAJIT_DIR/src/?.lua" # Required because LuaJIT needs the find its jit library to generate optimized bytecode
echo "Generating optimized bytecode..."
SCRIPT_ROOT="$PROJECT_ROOT/Runtime/LuaEnvironment"

SECONDS=0
COMPILED_LUA_SCRIPTS=""
for LUA_SCRIPT_PATH in $(cat $LUA_SOURCES_LIST)
do
	OUTPUT_FILE_NAME=$(basename $LUA_SCRIPT_PATH .lua)
	echo "Saving bytecode for $LUA_SCRIPT_PATH -> $OUTPUT_FILE_NAME.o"
	OUTPUT_FILE_PATH=$LUAJIT_DIR/$OUTPUT_FILE_NAME.o
	COMPILED_LUA_SCRIPTS+="$OUTPUT_FILE_PATH "
	$LUAJIT_DIR/src/luajit -b $LUA_SCRIPT_PATH $OUTPUT_FILE_PATH
done
echo "Finished generating optimized bytecode (in $SECONDS s)"
# TODO re package?

# Build runtime (simplified to work around obnoxious cmake issues)
EVO_VERSION_STRING=$(git describe --tags)
DEFINES="LUVI_VERSION=\"$EVO_VERSION_STRING\""

echo "Compiling and linking..."
SECONDS=0
SRC_DIR=$PROJECT_ROOT/Runtime
$COMPILE_COMMAND -D$DEFINES -I$LUAJIT_DIR/src  -I$LUV_DIR/src -I$LLHTTP_DIR/include  -I$COMPAT_DIR -I$COMPAT_DIR/c-api -I$SRC_DIR  $SRC_DIR/luvi_compat.c $SRC_DIR/main.c $LUV_DIR/libluv.a $LUV_DIR/deps/libuv/libuv_a.a $COMPAT_DIR/c-api/compat-5.3.c $LUAJIT_TARGET $LLHTTP_DIR/libllhttp.a $COMPILED_LUA_SCRIPTS -ldl -lm -pthread -o evo
echo "Finished compiling and linking (in $SECONDS s)"

echo "Finished creating evo build with tag $EVO_VERSION_STRING"