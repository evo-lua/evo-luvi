NUM_PARALLEL_JOBS=$(nproc)

echo "Building target openssl with $NUM_PARALLEL_JOBS jobs"

BUILD_DIR=ninjabuild-unix
OPENSSL_DIR=deps/openssl

cd $OPENSSL_DIR

./config

make clean
make -j $NUM_PARALLEL_JOBS
make test -j $NUM_PARALLEL_JOBS

cd -

cp $OPENSSL_DIR/libcrypto.a $BUILD_DIR
cp $OPENSSL_DIR/libssl.a $BUILD_DIR
