"../../../luvi.exe" . -o bundle.exe
mkdir temp
move bundle.exe temp
cd temp
"bundle.exe"
cd ..
rmdir temp /S /Q
