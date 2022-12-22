echo Building target raylib-lua

LUARAYLIB_DIR=deps/raylib-lua
RAYLIB_DIR=deps/raylib-lua/raylib/src
BUILD_DIR=ninjabuild-unix

cd $LUARAYLIB_DIR

make clean
make

cd -

cp $LUARAYLIB_DIR/libraylua.a $BUILD_DIR
cp $RAYLIB_DIR/libraylib.a $BUILD_DIR
