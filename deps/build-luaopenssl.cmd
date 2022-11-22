@echo off

ECHO Building target lua-openssl

SET SRC_DIR=deps\lua-openssl
SET BUILD_DIR=%SRC_DIR%\cmakebuild-windows
SET OUT_DIR=ninjabuild-windows

REM Include paths must be relative to the lua-openssl directory (NOT the project root)
SET LUAJIT_SRC_DIR=..\..\deps\luv\deps\luajit\src

SET OPENSSL_DIR=%BUILD_DIR%
SET OPENSSL_INCLUDE_DIR=deps\openssl\include

cmake -S %SRC_DIR% -B %BUILD_DIR% -G Ninja -DBUILD_SHARED_LUA_OPENSSL=OFF -DOPENSSL_ROOT_DIR=%OPENSSL_DIR%  -DOPENSSL_INCLUDE_DIR=%OPENSSL_INCLUDE_DIR% -DLUAJIT_INCLUDE_DIRS=%LUAJIT_SRC_DIR% -DLUA_INCLUDE_DIR=%LUAJIT_SRC_DIR% -DCMAKE_C_COMPILER=gcc
cmake --build %BUILD_DIR% --clean-first

COPY %BUILD_DIR%\openssl.a %OUT_DIR%
