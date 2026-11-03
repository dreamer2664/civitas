#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/../.."
python tools/walkaudit/bootstrap_tools.py
export PATH="$HOME/bin:$PATH"
selene src/server/Walkability src/server/Spawn tests/walk tools/walkaudit
stylua --check src/server/Walkability src/server/Spawn tests/walk tools/walkaudit
luau-lsp analyze --platform=standard src/server/Walkability/Audit.luau src/server/Spawn/Plan.luau src/server/Spawn/RecommendedPlan.luau tests/walk/run.luau src/server/Walkability/OrientedAudit.luau tests/walk/oriented.luau src/server/Walkability/StreetChecks.luau tests/walk/streets.luau
lune run tests/walk/run.luau
lune run tests/walk/oriented.luau
lune run tests/walk/streets.luau
python tests/walk/test_world_audit.py
python tests/walk/test_streaming.py
python tests/walk/test_sightlines.py
python tests/walk/test_parks.py
lune run tools/world/test_city.luau
rojo build default.project.json -o docs/reports/walkability-milestone.rbxlx
# Executes the same generator AND builder that the server loads, under Lune only.
status=0
lune run tools/walkaudit/check_world.luau || status=$?
lune run tools/walkaudit/street_checks.luau || status=$?
python tools/walkaudit/audit_world.py || status=$?
python tools/walkaudit/streaming.py
python tools/walkaudit/compare.py
python tools/walkaudit/parks.py
python tools/walkaudit/sightlines.py || status=$?
python tools/walkaudit/measure.py
python tools/walkaudit/render_world.py
echo 'Geometry checks only. Collision policy, platform exit and engine profiling are separate gates.'
exit "$status"
