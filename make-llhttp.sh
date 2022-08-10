gcc -O3 -Ideps/llhttp-ffi/llhttp/build -Ideps/llhttp-ffi/llhttp/build/c c-benchmark.c deps/llhttp-ffi/llhttp/libllhttp.a -o cbench.exe && ./cbench.exe
