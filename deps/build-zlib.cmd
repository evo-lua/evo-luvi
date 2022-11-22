@echo off

ECHO Building target zlib

SET OUT_DIR=ninjabuild-windows
SET SRC_DIR=deps\zlib
SET BUILD_DIR=%SRC_DIR%\cmakebuild-windows

cmake -S %SRC_DIR% -B %BUILD_DIR% -G Ninja -DBUILD_SHARED_LIBS=OFF -DCMAKE_C_COMPILER=gcc
cmake --build %BUILD_DIR% --clean-first

COPY %BUILD_DIR%\libzlibstatic.a %OUT_DIR%\zlibstatic.a