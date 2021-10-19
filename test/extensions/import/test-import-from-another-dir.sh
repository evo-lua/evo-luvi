set -e
cd .. && ../../luvi import -- import/main.lua
cd import/subfolder && ../../../../luvi .. -- ../main.lua && cd ..
