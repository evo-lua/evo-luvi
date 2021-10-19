"../../../luvi.exe" .
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

"../../../luvi.exe" . -- main.lua
IF %ERRORLEVEL% NEQ 0 EXIT /B 1