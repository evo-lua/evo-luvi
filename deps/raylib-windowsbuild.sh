echo Building target raylib-lua

LUARAYLIB_DIR=deps/raylib-lua
RAYLIB_DIR=deps/raylib-lua/raylib/src
BUILD_DIR=ninjabuild-windows

# raylib-lua's makefile seems to require some autogeneration via Lua scripts, but the Linux binary is hardcoded (sigh)
LUAJIT_EXE=$(pwd)/$BUILD_DIR/luajit.exe # Must be absolute path since raylib-lua uses it to generate the bindings

cd $LUARAYLIB_DIR

# ... and raylib'c "clean" command miserably fails on Windows/MSYS2 because it hardcoded cmd, without /c flag...
# Also, it always uses del but that doesn't exist in MSYS2 :/
# alias del=rm -rf # Fail gracefully if this is the first run
# alias cmd=sh
make clean PLATFORM_SHELL=sh #SHELL=sh
make LUA=$LUAJIT_EXE PLATFORM_SHELL=sh # SHELL=sh

cd -

cp $LUARAYLIB_DIR/libraylua.a $BUILD_DIR
cp $RAYLIB_DIR/libraylib.a $BUILD_DIR
