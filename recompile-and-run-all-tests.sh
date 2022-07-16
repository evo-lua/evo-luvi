set -e
make regular
make
make test

# See windows batch version for explanations of these steps
cp build/luvi ./luvi
./luvi test

# Regression tests for -v and -h flags (to fail the CI)
./luvi -v
./luvi --version
./luvi -h
./luvi --help

cd test/extensions/import
./test-import-from-cwd.sh
./test-import-from-another-dir.sh
./test-import-from-compiled-bundle.sh

cd ../../..

mv luvi evo-luvi