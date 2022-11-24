set -e
cd .. && ../../evo import -- import/main.lua
cd import/subfolder && ../../../../evo .. -- ../main.lua && cd ..
