#!/usr/bin/env bash
# Install the Debian Blender package for headless build/export jobs.
set -euo pipefail
if ! command -v blender >/dev/null 2>&1; then
  if [[ "$(id -u)" == 0 ]]; then
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y blender=4.3.2+dfsg-2 blender-data=4.3.2+dfsg-2
  else
    sudo -n apt-get update
    sudo -n env DEBIAN_FRONTEND=noninteractive apt-get install -y blender=4.3.2+dfsg-2 blender-data=4.3.2+dfsg-2
  fi
fi
blender -b --version
[[ "$(blender --version | head -n 1)" == "Blender 4.3.2" ]] || { echo "Expected Blender 4.3.2" >&2; exit 1; }
