@echo off

ECHO Building target llhttp

SET SRC_DIR=deps\llhttp-ffi\llhttp
SET BUILD_DIR=%SRC_DIR%\cmakebuild-windows
SET OUT_DIR=ninjabuild-windows

cmake -S %SRC_DIR% -B %BUILD_DIR% -G Ninja -DBUILD_SHARED_LIBS=OFF -DBUILD_STATIC_LIBS=ON -DCMAKE_C_COMPILER=gcc
cmake --build %BUILD_DIR% --clean-first

COPY %BUILD_DIR%\libllhttp.a %OUT_DIR%
