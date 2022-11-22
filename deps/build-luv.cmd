@echo off

ECHO Building target luv

SET SRC_DIR=deps\luv
SET BUILD_DIR=%SRC_DIR%\cmakebuild-windows
SET OUT_DIR=ninjabuild-windows

cmake -S %SRC_DIR% -B %BUILD_DIR% -G Ninja -DBUILD_MODULE=OFF -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DCMAKE_C_COMPILER=gcc
cmake --build %BUILD_DIR% --clean-first

REM Technically luv also builds LuaJIT (again), but it sometimes segfaults in JIT'ed code, so use the original instead to be safe
COPY %BUILD_DIR%\libluv.a %OUT_DIR%
COPY %BUILD_DIR%\deps\libuv\libuv_a.a %OUT_DIR%
