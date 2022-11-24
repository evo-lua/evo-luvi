"../../../evo.exe" . -o bundle.exe
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

mkdir temp
move bundle.exe temp
cd temp

"bundle.exe"
IF %ERRORLEVEL% NEQ 0 EXIT /B 1

cd ..
rmdir temp /S /Q
