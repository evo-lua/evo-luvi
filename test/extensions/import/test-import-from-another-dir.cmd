cd .. && "../../evo.exe" import -- import/main.lua
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

cd import/subfolder && "../../../../evo.exe" .. -- ../main.lua && cd ..
IF %ERRORLEVEL% NEQ 0 EXIT /B 1