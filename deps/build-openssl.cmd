@REM All this MUST be ran from MSYS2! OpenSSL's build system is the stuff of nightmares, and doesn't work with native perl
@REM The standard gcc won't work either, so make sure to install this one first (and all the other tools required):
@REM pacman -S git make mingw-w64-x86_64-gcc ninja mingw-w64-x86_64-cmake --noconfirm

@echo off

@REM Beware, the magic globals... This should work on all relevant systems, though?
SET NUM_PARALLEL_JOBS=%NUMBER_OF_PROCESSORS%

ECHO Building target openssl with %NUM_PARALLEL_JOBS% jobs

SET BUILD_DIR=ninjabuild-windows
SET OPENSSL_DIR=deps\openssl

PUSHD %OPENSSL_DIR%

perl Configure mingw64

make clean
make -j %NUM_PARALLEL_JOBS%
make test -j %NUM_PARALLEL_JOBS%

POPD

MOVE %OPENSSL_DIR%\libcrypto.a %BUILD_DIR%
MOVE %OPENSSL_DIR%\libssl.a %BUILD_DIR%