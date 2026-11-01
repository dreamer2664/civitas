#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
export PATH="$HOME/bin:$PATH"
selene src/server/Walkability src/server/Spawn tests/walk tools/walkaudit
stylua --check src/server/Walkability src/server/Spawn tests/walk tools/walkaudit
luau-lsp analyze --platform=standard src/server/Walkability/Audit.luau src/server/Spawn/Plan.luau tests/walk/run.luau
lune run tests/walk/run.luau
rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx
# Intentionally exits nonzero without real world data; fixtures cannot satisfy this gate.
status=0
lune run tools/walkaudit/run.luau "$@" || status=$?
python tools/walkaudit/measure.py
python tools/walkaudit/render.py
exit "$status"
