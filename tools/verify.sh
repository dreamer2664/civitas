#!/usr/bin/env bash
# World + shared-code verification. The Roblox API definitions are fetched, never stubbed out.
# Run from any directory: ./tools/verify.sh
set -euo pipefail

cd "$(dirname "$0")/.."
export PATH="$HOME/bin:$PATH"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/civitas"
DEFINITIONS="$CACHE_DIR/globalTypes.d.luau"
SOURCEMAP="/tmp/civitas-verify-sourcemap.json"
mkdir -p "$CACHE_DIR"
if [[ ! -s "$DEFINITIONS" ]]; then
  curl -fsSL https://raw.githubusercontent.com/JohnnyMorganz/luau-lsp/main/scripts/globalTypes.d.luau -o "$DEFINITIONS.tmp"
  mv "$DEFINITIONS.tmp" "$DEFINITIONS"
fi

printf '== selene src/ ==\n'
selene src/
printf '== stylua --check src/ tests/ tools/world/ ==\n'
stylua --check src/ tests/ tools/world/
printf '== rojo sourcemap + Roblox API definitions ==\n'
rojo sourcemap default.project.json --output "$SOURCEMAP"
luau-lsp analyze --platform=roblox --definitions "@roblox=$DEFINITIONS" --sourcemap "$SOURCEMAP" src/server/World/*.luau
printf '== lune shared tests ==\n'
lune run tests/run.luau
printf '== lune generated-city acceptance tests ==\n'
lune run tools/world/test_city.luau
printf '== deterministic city export + plan/street-level renders ==\n'
lune run tools/world/export_plan.luau
python3 tools/world/render_city.py
printf '== rojo build committed place file ==\n'
rojo build default.project.json -o tools/world/civitas-world-blockout.rbxlx
printf 'ALL CHECKS PASSED\n'
