@echo off

ECHO Building target luajit

SET BUILD_DIR=ninjabuild-windows

PUSHD deps\luv\deps\luajit\src

make clean
make BUILDMODE=static XCFLAGS=-DLUAJIT_ENABLE_LUA52COMPAT

POPD

COPY deps\luv\deps\luajit\src\luajit.exe %BUILD_DIR%
COPY deps\luv\deps\luajit\src\libluajit.a %BUILD_DIR%

IF NOT EXIST "%BUILD_DIR%\jit" mkdir %BUILD_DIR%\jit

REM This is needed to save bytecode via luajit -b since the jit module isn't embedded inside the executable
COPY deps\luv\deps\luajit\src\jit %BUILD_DIR%\jit

REM Basic smoke test to ensure it was statically linked (else a DLL error should occur)
"%BUILD_DIR%\luajit.exe" -e "print(\"Hello from LuaJIT! (This is a test and can be ignored)\")"