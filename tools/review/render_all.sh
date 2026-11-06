#!/usr/bin/env bash
# Each camera gets its own process to bound Cycles memory on a 2 GiB machine.
set -euo pipefail
cd "$(dirname "$0")/../.."
mkdir -p evidence/norman/renders
for camera in 01-central-arrival 02-garden-platform 03-historic-core 04-network-context 05-shuttle-detail 06-station-front; do
  python tools/review/render_geometry.py --samples "${CIV_RENDER_SAMPLES:-24}" --only "$camera"
done
