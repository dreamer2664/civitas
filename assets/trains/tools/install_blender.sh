#!/usr/bin/env bash
# Install the Debian Blender package for headless build/export jobs.
set -euo pipefail
if ! command -v blender >/dev/null 2>&1; then
  if [[ "$(id -u)" == 0 ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y blender
  else
    sudo -n apt-get update
    sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y blender
  fi
fi
blender -b --version
