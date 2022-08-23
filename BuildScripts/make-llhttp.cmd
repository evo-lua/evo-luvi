REM Prerequisites: cmake, any supported C compiler (needs to be set up so that cmake can find it)
set cwd=%cd%
cd ..\deps\llhttp-ffi\llhttp
cmake --build . --config Release
cd %cwd%
move ..\deps\llhttp-ffi\llhttp\Release\llhttp.lib ..\ninjabuild\llhttp\llhttp.lib

REM build $builddir\llhttp\llhttp.lib: run $cwd/BuildScripts/make-llhttp.cmd
REM rule run
REM command = $in