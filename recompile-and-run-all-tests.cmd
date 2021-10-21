@echo off
REM You may need to run this from a Visual Studio prompt if using MSVC (no idea about gcc)
REM Example: x64 Native Tools Command Prompt for VS <version>

REM This should set up the build environment for standard builds the first time it's run
CALL make.bat regular
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

CALL make.bat
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

CALL make.bat test
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

REM The extension test suite is a Luvi app we can simply run after the build
luvi.exe test
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

REM The tests for the import extension are implemented as a separate Luvi app and need to be run from multiple directories
cd test/extensions/import

CALL test-import-from-cwd.cmd
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

CALL test-import-from-another-dir.cmd
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

CALL test-import-from-compiled-bundle.cmd
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

REM This is just added for convenience when repeatedly calling the script via CLI
cd ../../..

REM Make sure the exit code is EXIT_SUCCESS when using --version or --help (Regression)
luvi.exe --version
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
luvi.exe -v
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
luvi.exe --help
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
luvi.exe -h
IF %ERRORLEVEL% NEQ 0 EXIT /B 1