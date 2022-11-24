set -e
../../../evo . -o bundle
mkdir temp
mv bundle temp
cd temp
./bundle
cd ..
rm -rfv temp
