@echo off
REM You may need to run this from a Visual Studio prompt if using MSVC (no idea about gcc)
REM Example: x64 Native Tools Command Prompt for VS <version>

REM Since luvi won't pass the CLI arguments before the "--" delimiter to the bundled app,
REM they have to be passed manually for now (yes, it's ugly)
CALL make.bat
luvi.exe test
cd test/extensions/import
CALL test-import-from-cwd.cmd
CALL test-import-from-another-dir.cmd
CALL test-import-from-compiled-bundle.cmd
cd ../../..