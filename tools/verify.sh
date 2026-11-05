#!/usr/bin/env bash
# One command that runs every static and unit check for the client and the world lane, in the order
# the standards list them. Exits non-zero at the first failure. Run from anywhere; it changes to the repo root.
#
#   tools/install-tools.sh   (once per machine: pinned toolchain + Roblox definitions)
#   tools/verify.sh
#
# What it does NOT prove: anything about Roblox Studio, rendering, touch feel or multiplayer.
# Those are the Manager's Studio checks and are recorded in docs/MILESTONES.md.
set -euo pipefail
cd "$(dirname "$0")/.."
export PATH="$HOME/.local/bin:$PATH"
CACHE="${CIV_CACHE:-$HOME/.cache/civitas}"
DEFS="$CACHE/globalTypes.d.lua"
DUMP="$CACHE/Full-API-Dump.json"

for tool in stylua selene luau-lsp lune rojo python3; do
  command -v "$tool" >/dev/null || { echo "missing tool: $tool (run tools/install-tools.sh)"; exit 2; }
done
[ -s "$DEFS" ] && [ -s "$DUMP" ] || { echo "missing Roblox definitions in $CACHE (run tools/install-tools.sh)"; exit 2; }

step() { printf '\n== %s\n' "$1"; }

step "stylua --check (formatting)"
stylua --check src tests
echo "ok"

step "selene (lints)"
selene src tests

step "rojo sourcemap"
mkdir -p build
rojo sourcemap default.project.json --output build/sourcemap.json

# analyse <label> <paths...>: runs luau-lsp once, shows its diagnostics, and fails on any of them.
# luau-lsp exits 0 even with type errors in some versions, so the output is inspected, not the code.
analyse() {
  local label="$1"; shift
  step "$label"
  local out
  out="$(luau-lsp analyze "$@" 2>&1 || true)"
  printf '%s\n' "$out" | grep -v '^\[INFO\]\|^\[WARN\]' || true
  if printf '%s\n' "$out" | grep -q 'TypeError\|SyntaxError\|LintWarning\|Error:'; then
    echo "luau-lsp reported diagnostics for: $label"
    exit 1
  fi
  echo "0 diagnostics"
}

analyse "luau-lsp analyze: src/client (strict, Roblox definitions)" \
  --definitions="$DEFS" --sourcemap=build/sourcemap.json --base-luaurc=.luaurc src/client

analyse "luau-lsp analyze: shared contracts (types only, no Roblox globals)" \
  --platform=standard --base-luaurc=.luaurc src/shared/Contracts

# Vector's runtime modules are types-plus-pure-Luau and checked without Roblox definitions.
analyse "luau-lsp analyze: src/shared/Rail (pure, standard)" \
  --platform=standard --base-luaurc=.luaurc src/shared/Rail

step "gen_network --check (map data matches docs/rail/NETWORK.md)"
python3 tools/gen_network.py --check

step "check_enums (Roblox names vs API dump)"
python3 tools/check_enums.py --dump "$DUMP"

step "check_streaming (no Workspace in client code)"
python3 tools/check_streaming.py

step "facade decoration collision policy (static)"
python3 tools/world/check_facade_collision.py

step "lune unit tests"
lune run tests/run.luau

step "stylua --check (world tools)"
stylua --check tools/world

# World lane (vector/pave/strata on main): server World analysis, city acceptance and export.
analyse "luau-lsp analyze: src/server/World (strict, Roblox definitions)" \
  --definitions="$DEFS" --sourcemap=build/sourcemap.json --base-luaurc=.luaurc src/server/World

analyse "luau-lsp analyze: experimental in-city railway (strict, Roblox definitions)" \
  --definitions="$DEFS" --sourcemap=build/sourcemap.json --base-luaurc=.luaurc src/server/RailDemo

step "lune generated-city acceptance tests"
lune run tools/world/test_city.luau

step "deterministic city export + plan/street-level renders"
lune run tools/world/export_plan.luau
python3 tools/world/render_city.py
python3 tools/world/render_station_shuttle.py

step "interface concept renders (not Studio screenshots)"
python3 tools/world/render_interface.py

step "rojo build (place file)"
rojo build default.project.json --output build/civitas.rbxlx
echo "built build/civitas.rbxlx ($(stat -c %s build/civitas.rbxlx) bytes)"
python3 tools/check_place_contents.py build/civitas.rbxlx

step "isolated rail-test lint and sourcemap"
stylua --check prototypes/rail tools/measure_train_simulation.luau
selene prototypes/rail tools/measure_train_simulation.luau
rojo sourcemap rail-test.project.json --output build/rail-test-sourcemap.json
analyse "luau-lsp analyze: isolated rail-test scripts" \
  --definitions="$DEFS" --sourcemap=build/rail-test-sourcemap.json --base-luaurc=.luaurc prototypes/rail

step "prototype simulation evidence and concept renders"
lune run tools/measure_train_simulation.luau
python3 tools/render_train_simulation.py
python3 tools/render_rail_test.py
python3 tools/render_rail_controls.py

step "rojo build (isolated rail-test place)"
rojo build rail-test.project.json --output build/rail-test.rbxlx
echo "built build/rail-test.rbxlx ($(stat -c %s build/rail-test.rbxlx) bytes)"

step "evidence"
echo "api dump sha256: $(sha256sum "$DUMP" | cut -d' ' -f1)"
echo "luau-lsp $(luau-lsp --version) | selene $(selene --version | cut -d' ' -f2) | lune $(lune --version | cut -d' ' -f2) | rojo $(rojo --version | cut -d' ' -f2) | stylua $(stylua --version | cut -d' ' -f2)"
echo "verify: all checks passed"
