#!/usr/bin/env bash
# Phase 1/2 verification script for CODE · vector.
# Usage: ./tools/verify.sh   (run from the repo root)
# Requires the toolchain on PATH: selene, stylua, luau-lsp, lune, rojo
# (installed under $HOME/bin in this sandbox).
set -euo pipefail

cd "$(dirname "$0")/.."

export PATH="$HOME/bin:$PATH"

echo "== selene src/ =="
selene src/

echo "== stylua --check src/ tests/ tools/ =="
stylua --check src/ tests/ tools/

echo "== luau-lsp analyze --platform=standard --definitions=tools/globalTypes.d.luau =="
luau-lsp analyze --platform=standard --definitions=tools/globalTypes.d.luau \
  src/server/Services/TrainService.luau \
  src/shared/Rail/Spline.luau \
  src/shared/Rail/Kinematics.luau \
  src/shared/Contracts/GeometryContract.luau \
  src/shared/Contracts/RailContract.luau \
  src/shared/Contracts/RemoteContract.luau

echo "== lune run tests/run.luau =="
lune run tests/run.luau

echo "== rojo build (place file to /tmp, not committed) =="
rojo build default.project.json -o /tmp/civitas-verify.rbxlx

echo "ALL CHECKS PASSED"
