cd .. && "../../luvi.exe" import -- import/main.lua
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

cd import/subfolder && "../../../../luvi.exe" .. -- ../main.lua && cd ..
IF %ERRORLEVEL% NEQ 0 EXIT /B 1