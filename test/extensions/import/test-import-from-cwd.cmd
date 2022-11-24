"../../../evo.exe" .
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

"../../../evo.exe" . -- main.lua
IF %ERRORLEVEL% NEQ 0 EXIT /B 1