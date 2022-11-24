if ! test -f evo; then
	./unixbuild.sh
	cp ninjabuild-unix/evo .
fi

# Regression tests for -v and -h flags (to fail the CI)
./evo -v
./evo --version
./evo -h
./evo --help

./evo samples/test.app -- 1 2 3 4
./evo samples/test.app -o test.app.zip
./test.app.zip 1 2 3 4
rm -f test.app.zip

# Running this as part of the test makes no sense, but keep it around anyway until a future cleanup pass
./evo samples/repl.app -o repl.app.zip
rm -rf repl.app.zip

# Legacy tests for the import builtin
cd test/extensions/import

./test-import-from-cwd.sh
./test-import-from-another-dir.sh
./test-import-from-compiled-bundle.sh

cd -
