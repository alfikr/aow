#!/usr/bin/env bash
# Menjalankan semua uji headless. Pakai: GODOT=/path/ke/godot tools/run_tests.sh
set -uo pipefail
GODOT="${GODOT:-godot}"
cd "$(dirname "$0")/.."

"$GODOT" --headless --path . --import >/dev/null 2>&1

fail=0
for scene in smoke validate; do
  echo "== $scene =="
  out="$("$GODOT" --headless --path . "res://tests/$scene.tscn" 2>&1)"
  echo "$out" | grep -E "FAIL|MASALAH|HASIL|SCRIPT ERROR" || true
  echo "$out" | grep -q "HASIL: LULUS" || fail=1
done

echo "== soak (120 hari) =="
out="$("$GODOT" --headless --path . res://tests/soak.tscn -- 120 1 2>&1)"
echo "$out" | grep -E "SOAK|INVARIAN|SCRIPT ERROR" || true
echo "$out" | grep -q "SOAK selesai" || fail=1
echo "$out" | grep -qE "SCRIPT ERROR|INVARIAN" && fail=1

[ "$fail" -eq 0 ] && echo "SEMUA LULUS" || { echo "ADA YANG GAGAL"; exit 1; }
