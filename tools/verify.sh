#!/usr/bin/env bash
# Phase 1 verification script for CODE · vector.
# Usage: ./tools/verify.sh   (run from the repo root)
# Requires the toolchain on PATH: selene, stylua, luau-lsp, lune, rojo
# (installed under $HOME/bin in this sandbox).
set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="$HOME/bin:$PATH"

echo "== selene src/ =="
selene src/

echo "== stylua --check src/ tests/ =="
stylua --check src/ tests/

echo "== luau-lsp analyze --platform=standard src/shared/Rail/ =="
luau-lsp analyze --platform=standard src/shared/Rail/Spline.luau src/shared/Rail/Kinematics.luau

echo "== lune run tests/run.luau =="
lune run tests/run.luau

echo "== rojo build (place file to /tmp, not committed) =="
rojo build default.project.json -o /tmp/civitas-verify.rbxlx

echo "ALL CHECKS PASSED"
