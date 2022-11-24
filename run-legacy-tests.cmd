@echo off

IF NOT EXIST evo.exe (
	CALL windowsbuild.cmd
	IF %ERRORLEVEL% NEQ 0 EXIT /B 1
	COPY ninjabuild-windows\evo.exe .
	IF %ERRORLEVEL% NEQ 0 EXIT /B 1
)

REM Make sure the exit code is EXIT_SUCCESS when using --version or --help (Regression)
evo.exe --version
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
evo.exe -v
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
evo.exe --help
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
evo.exe -h
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

evo.exe samples\test.app -- 1 2 3 4
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
evo.exe samples\test.app -o test.exe
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
test.exe 1 2 3 4
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
DEL /Q test.exe

REM Running this as part of the test makes no sense, but keep it around anyway until a future cleanup pass
evo.exe samples/repl.app -o repl.exe
IF %ERRORLEVEL% NEQ 0 EXIT /B 1
DEL /Q repl.exe

REM The tests for the import extension are implemented as a separate Luvi app and need to be run from multiple directories
PUSHD test\extensions\import

CALL test-import-from-cwd.cmd
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

CALL test-import-from-another-dir.cmd
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

CALL test-import-from-compiled-bundle.cmd
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

POPD