#!/usr/bin/env bash
# Membuat binary Linux mandiri (tanpa Godot terpasang di komputer pemain).
# Syarat: Godot 4.3 dan export template 4.3 terpasang
#   (Editor > Project > Export > Manage Export Templates > Download and Install).
# Pakai: GODOT=/path/ke/godot tools/build_linux.sh
set -euo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."
mkdir -p build
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-release "Linux" build/lembah-panen.x86_64
chmod +x build/lembah-panen.x86_64
echo "Selesai: build/lembah-panen.x86_64"
