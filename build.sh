#!/bin/sh
# ビルド: ./build.sh  → build/ddgo-cabdisplay ができる
set -e
cd "$(dirname "$0")"
cmake -S . -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build -j"$(nproc)"
echo "できました: $(pwd)/build/ddgo-cabdisplay"
