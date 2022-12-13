SRC_DIR=Benchmarks/native-llhttp-benchmark/
LLHTTP_DIR=deps/llhttp/include
LLHTTP_LIB=ninjabuild-unix/libllhttp.a

gcc $SRC_DIR/native-llhttp-benchmark.c -o $SRC_DIR/benchmark $LLHTTP_LIB -I $LLHTTP_DIR -O2 -Wall

time $SRC_DIR/benchmark